package File::KDBX::IO::Crypt;
# ABSTRACT: Encrypter/decrypter IO handle

use warnings;
use strict;

use Errno;
use File::KDBX::Error;
use File::KDBX::Util qw(:class :empty);
use namespace::clean;

extends 'File::KDBX::IO';

our $VERSION = '0.904'; # VERSION
our $BUFFER_SIZE = 16384;
our $ERROR;


my %ATTRS = (
    cipher  => undef,
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
    $self->cipher($args{cipher}) or throw 'Cipher required';
    return $self;
}

sub _FILL {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FILL\t$self\n";
    my $cipher = $self->cipher or return;

    $fh->read(my $buf = '', $BUFFER_SIZE);
    if (0 < length($buf)) {
        my $plaintext = eval { $cipher->decrypt($buf) };
        if (my $err = $@) {
            $self->_set_error($err);
            return;
        }
        return $plaintext if 0 < length($plaintext);
    }

    # finish
    my $plaintext = eval { $cipher->finish };
    if (my $err = $@) {
        $self->_set_error($err);
        return;
    }
    $self->cipher(undef);
    return $plaintext;
}

sub _WRITE {
    my ($self, $buf, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "WRITE\t$self\n";
    my $cipher = $self->cipher or return 0;

    my $new_data = eval { $cipher->encrypt($buf) } || '';
    if (my $err = $@) {
        $self->_set_error($err);
        return 0;
    }
    $self->_buffer_out_add($new_data) if nonempty $new_data;
    return length($buf);
}

sub _POPPED {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "POPPED\t$self\n";
    return if $self->_mode ne 'w';
    my $cipher = $self->cipher or return;

    my $new_data = eval { $cipher->finish } || '';
    if (my $err = $@) {
        $self->_set_error($err);
        return;
    }
    $self->_buffer_out_add($new_data) if nonempty $new_data;

    $self->cipher(undef);
    $self->_FLUSH($fh);
}

sub _FLUSH {
    my ($self, $fh) = @_;

    $ENV{DEBUG_STREAM} and print STDERR "FLUSH\t$self\n";
    return if $self->_mode ne 'w';

    my $buffer = $self->_buffer_out;
    while (@$buffer) {
        my $read = shift @$buffer;
        next if empty $read;
        $fh->print($read) or return -1;
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
    $self->cipher(undef);
    $self->_error($ERROR = File::KDBX::Error->new(@_));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::IO::Crypt - Encrypter/decrypter IO handle

=head1 VERSION

version 0.904

=head1 SYNOPSIS

    use File::KDBX::IO::Crypt;
    use File::KDBX::Cipher;

    my $cipher = File::KDBX::Cipher->new(...);

    open(my $out_fh, '>:raw', 'ciphertext.bin');
    $out_fh = File::KDBX::IO::Crypt->new($out_fh, cipher => $cipher);

    print $out_fh $plaintext;

    close($out_fh);

    open(my $in_fh, '<:raw', 'ciphertext.bin');
    $in_fh = File::KDBX::IO::Crypt->new($in_fh, cipher => $cipher);

    my $plaintext = do { local $/; <$in_fh> );

    close($in_fh);

=head1 ATTRIBUTES

=head2 cipher

A L<File::KDBX::Cipher> instance to do the actual encryption or decryption.

=head1 METHODS

=head2 new

    $fh = File::KDBX::IO::Crypt->new(%attributes);
    $fh = File::KDBX::IO::Crypt->new($fh, %attributes);

Construct a new crypto IO handle.

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
