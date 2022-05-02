package File::KDBX::IO::HmacBlock;
# ABSTRACT: HMAC block stream IO handle

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Crypt::Mac::HMAC qw(hmac);
use Errno;
use File::KDBX::Error;
use File::KDBX::Util qw(:class :io assert_64bit);
use namespace::clean;

extends 'File::KDBX::IO';

our $VERSION = '0.901'; # VERSION
our $BLOCK_SIZE = 1048576;  # 1MiB
our $ERROR;


my %ATTRS = (
    _block_index    => 0,
    _buffer         => sub { \(my $buf = '') },
    _finished       => 0,
    block_size      => sub { $BLOCK_SIZE },
    key             => undef,
);
while (my ($attr, $default) = each %ATTRS) {
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    *$attr = sub {
        my $self = shift;
        *$self->{$attr} = shift if @_;
        *$self->{$attr} //= (ref $default eq 'CODE') ? $default->($self) : $default;
    };
}


sub new {
    assert_64bit;

    my $class = shift;
    my %args = @_ % 2 == 1 ? (fh => shift, @_) : @_;
    my $self = $class->SUPER::new;
    $self->_fh($args{fh}) or throw 'IO handle required';
    $self->key($args{key}) or throw 'Key required';
    $self->block_size($args{block_size});
    $self->_buffer;
    return $self;
}

sub _FILL {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FILL\t$self\n";
    return if $self->_finished;

    my $block = eval { $self->_read_hashed_block($fh) };
    if (my $err = $@) {
        $self->_set_error($err);
        return;
    }
    if (length($block) == 0) {
        $self->_finished(1);
        return;
    }
    return $block;
}

sub _WRITE {
    my ($self, $buf, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "WRITE\t$self ($fh)\n";
    return 0 if $self->_finished;

    ${*$self->{_buffer}} .= $buf;

    $self->_FLUSH($fh);  # TODO only if autoflush?

    return length($buf);
}

sub _POPPED {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "POPPED\t$self ($fh)\n";
    return if $self->_mode ne 'w';

    $self->_FLUSH($fh);
    eval {
        $self->_write_next_hmac_block($fh);     # partial block with remaining content
        $self->_write_final_hmac_block($fh);    # terminating block
    };
    $self->_set_error($@) if $@;
}

sub _FLUSH {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FLUSH\t$self ($fh)\n";
    return if $self->_mode ne 'w';

    eval {
        while ($self->block_size <= length(${*$self->{_buffer}})) {
            $self->_write_next_hmac_block($fh);
        }
    };
    if (my $err = $@) {
        $self->_set_error($err);
        return -1;
    }

    return 0;
}

sub _set_error {
    my $self = shift;
    $ENV{DEBUG_STREAM} and print STDERR "err\t$self\n";
    if (exists &Errno::EPROTO) {
        $! = &Errno::EPROTO;
    }
    elsif (exists &Errno::EIO) {
        $! = &Errno::EIO;
    }
    $self->_error($ERROR = error(@_));
}

##############################################################################

sub _read_hashed_block {
    my $self = shift;
    my $fh = shift;

    read_all $fh, my $hmac, 32 or throw 'Failed to read HMAC';

    read_all $fh, my $packed_size, 4 or throw 'Failed to read HMAC block size';
    my ($size) = unpack('L<', $packed_size);

    my $block = '';
    if (0 < $size) {
        read_all $fh, $block, $size
            or throw 'Failed to read HMAC block', index => $self->_block_index, size => $size;
    }

    my $packed_index = pack('Q<', $self->_block_index);
    my $got_hmac = hmac('SHA256', $self->_hmac_key,
        $packed_index,
        $packed_size,
        $block,
    );

    $hmac eq $got_hmac
        or throw 'Block authentication failed', index => $self->_block_index, got => $got_hmac, expected => $hmac;

    *$self->{_block_index}++;
    return $block;
}

sub _write_next_hmac_block {
    my $self    = shift;
    my $fh      = shift;
    my $buffer  = shift // $self->_buffer;
    my $allow_empty = shift;

    my $size = length($$buffer);
    $size = $self->block_size if $self->block_size < $size;
    return 0 if $size == 0 && !$allow_empty;

    my $block = '';
    $block = substr($$buffer, 0, $size, '') if 0 < $size;

    my $packed_index = pack('Q<', $self->_block_index);
    my $packed_size  = pack('L<', $size);
    my $hmac = hmac('SHA256', $self->_hmac_key,
        $packed_index,
        $packed_size,
        $block,
    );

    $fh->print($hmac, $packed_size, $block)
        or throw 'Failed to write HMAC block', hmac => $hmac, block_size => $size;

    *$self->{_block_index}++;
    return 0;
}

sub _write_final_hmac_block {
    my $self = shift;
    my $fh = shift;

    $self->_write_next_hmac_block($fh, \'', 1);
}

sub _hmac_key {
    my $self = shift;
    my $key = shift // $self->key;
    my $index = shift // $self->_block_index;

    my $packed_index = pack('Q<', $index);
    my $hmac_key = digest_data('SHA512', $packed_index, $key);
    return $hmac_key;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::IO::HmacBlock - HMAC block stream IO handle

=head1 VERSION

version 0.901

=head1 DESCRIPTION

Writing to a HMAC-block stream handle will transform the data into a series of blocks. An HMAC is calculated
for each block and is included in the output.

Reading from a handle, each block will be verified and authenticated as the blocks are disassembled back into
a data stream.

This format helps ensure data integrity and authenticity of KDBX4 files.

Each block is encoded thusly:

=over 4

=item *

HMAC - 32 bytes, calculated over [block index (increments starting with 0), block size and data]

=item *

Block size - Little-endian unsigned 32-bit (counting only the data)

=item *

Data - String of bytes

=back

The terminating block is an empty block encoded as usual but block size is 0 and there is no data.

=head1 ATTRIBUTES

=head2 block_size

Desired block size when writing (default: C<$File::KDBX::IO::HmacBlock::BLOCK_SIZE> or 1,048,576 bytes)

=head2 key

HMAC-SHA256 key for authenticating the data stream (required)

=head1 METHODS

=head2 new

    $fh = File::KDBX::IO::HmacBlock->new(%attributes);
    $fh = File::KDBX::IO::HmacBlock->new($fh, %attributes);

Construct a new HMAC-block stream IO handle.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
