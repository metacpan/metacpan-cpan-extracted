package File::KDBX::IO::HashBlock;
# ABSTRACT: Hash block stream IO handle

use warnings;
use strict;

use Crypt::Digest qw(digest_data);
use Errno;
use File::KDBX::Error;
use File::KDBX::Util qw(:class :io);
use IO::Handle;
use namespace::clean;

extends 'File::KDBX::IO';

our $VERSION = '0.904'; # VERSION
our $ALGORITHM = 'SHA256';
our $BLOCK_SIZE = 1048576;  # 1MiB
our $ERROR;


my %ATTRS = (
    _block_index    => 0,
    _buffer         => sub { \(my $buf = '') },
    _finished       => 0,
    algorithm       => sub { $ALGORITHM },
    block_size      => sub { $BLOCK_SIZE },
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
    my $class = shift;
    my %args = @_ % 2 == 1 ? (fh => shift, @_) : @_;
    my $self = $class->SUPER::new;
    $self->_fh($args{fh}) or throw 'IO handle required';
    $self->algorithm($args{algorithm});
    $self->block_size($args{block_size});
    $self->_buffer;
    return $self;
}

sub _FILL {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FILL\t$self\n";
    return if $self->_finished;

    my $block = eval { $self->_read_hash_block($fh) };
    if (my $err = $@) {
        $self->_set_error($err);
        return;
    }
    return $$block if defined $block;
}

sub _WRITE {
    my ($self, $buf, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "WRITE\t$self\n";
    return 0 if $self->_finished;

    ${$self->_buffer} .= $buf;

    $self->_FLUSH($fh);

    return length($buf);
}

sub _POPPED {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "POPPED\t$self\n";
    return if $self->_mode ne 'w';

    $self->_FLUSH($fh);
    eval {
        $self->_write_next_hash_block($fh);     # partial block with remaining content
        $self->_write_final_hash_block($fh);    # terminating block
    };
    $self->_set_error($@) if $@;
}

sub _FLUSH {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FLUSH\t$self\n";
    return if $self->_mode ne 'w';

    eval {
        while ($self->block_size <= length(${*$self->{_buffer}})) {
            $self->_write_next_hash_block($fh);
        }
    };
    if (my $err = $@) {
        $self->_set_error($err);
        return -1;
    }

    return 0;
}

##############################################################################

sub _read_hash_block {
    my $self = shift;
    my $fh = shift;

    read_all $fh, my $buf, 4 or throw 'Failed to read hash block index';
    my ($index) = unpack('L<', $buf);

    $index == $self->_block_index or throw 'Invalid block index', index => $index;

    read_all $fh, my $hash, 32 or throw 'Failed to read hash';

    read_all $fh, $buf, 4 or throw 'Failed to read hash block size';
    my ($size) = unpack('L<', $buf);

    if ($size == 0) {
        $hash eq ("\0" x 32) or throw 'Invalid final block hash', hash => $hash;
        $self->_finished(1);
        return undef;
    }

    read_all $fh, my $block, $size or throw 'Failed to read hash block', index => $index, size => $size;

    my $got_hash = digest_data($self->algorithm, $block);
    $hash eq $got_hash
        or throw 'Hash mismatch', index => $index, size => $size, got => $got_hash, expected => $hash;

    *$self->{_block_index}++;
    return \$block;
}

sub _write_next_hash_block {
    my $self = shift;
    my $fh = shift;

    my $size = length(${$self->_buffer});
    $size = $self->block_size if $self->block_size < $size;
    return 0 if $size == 0;

    my $block = substr(${$self->_buffer}, 0, $size, '');

    my $buf = pack('L<', $self->_block_index);
    print $fh $buf or throw 'Failed to write hash block index';

    my $hash = digest_data($self->algorithm, $block);
    print $fh $hash or throw 'Failed to write hash';

    $buf = pack('L<', length($block));
    print $fh $buf or throw 'Failed to write hash block size';

    # $fh->write($block, $size) or throw 'Failed to hash write block';
    print $fh $block or throw 'Failed to hash write block';

    *$self->{_block_index}++;
    return 0;
}

sub _write_final_hash_block {
    my $self = shift;
    my $fh = shift;

    my $buf = pack('L<', $self->_block_index);
    print $fh $buf or throw 'Failed to write hash block index';

    my $hash = "\0" x 32;
    print $fh $hash or throw 'Failed to write hash';

    $buf = pack('L<', 0);
    print $fh $buf or throw 'Failed to write hash block size';

    $self->_finished(1);
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::IO::HashBlock - Hash block stream IO handle

=head1 VERSION

version 0.904

=head1 DESCRIPTION

Writing to a hash-block handle will transform the data into a series of blocks. Each block is hashed, and the
hash is included with the block in the stream.

Reading from a handle, each hash block will be verified as the blocks are disassembled back into a data
stream.

This format helps ensure data integrity of KDBX3 files.

Each block is encoded thusly:

=over 4

=item *

Block index - Little-endian unsigned 32-bit integer, increments starting with 0

=item *

Hash - 32 bytes

=item *

Block size - Little-endian unsigned 32-bit (counting only the data)

=item *

Data - String of bytes

=back

The terminating block is an empty block where hash is 32 null bytes, block size is 0 and there is no data.

=head1 ATTRIBUTES

=head2 algorithm

Digest algorithm in hash-blocking the stream (default: C<SHA-256>)

=head2 block_size

Desired block size when writing (default: C<$File::KDBX::IO::HashBlock::BLOCK_SIZE> or 1,048,576 bytes)

=head1 METHODS

=head2 new

    $fh = File::KDBX::IO::HashBlock->new(%attributes);
    $fh = File::KDBX::IO::HashBlock->new($fh, %attributes);

Construct a new hash-block stream IO handle.

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
