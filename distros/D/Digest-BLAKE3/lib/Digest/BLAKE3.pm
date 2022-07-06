package Digest::BLAKE3;

use 5.008009;
use strict;
use warnings;
use Carp
    qw(croak);
use parent
    qw(Digest::base);
require XSLoader;

our $VERSION = '0.002';

XSLoader::load(Digest::BLAKE3::, $VERSION);

sub new_hash
{
    my $self = shift(@_);

    unless (ref($self)) {
	$self = $self->_new();
    }
    $self->_init_hash(@_);
}

BEGIN {
    *new = \&new_hash;
}

sub new_keyed_hash
{
    my $self = shift(@_);

    unless (ref($self)) {
	$self = $self->_new();
    }
    $self->_init_keyed_hash(@_);
}

sub new_derive_key
{
    my $self = shift(@_);

    unless (ref($self)) {
	$self = $self->_new();
    }
    $self->_init_derive_key(@_);
}

sub mode
{
    my $self = shift(@_);

    qw(hash keyed_hash derive_key)[$self->_mode()];
}

sub addfile
{
    my $self = shift(@_);
    my $arg = shift(@_);
    my($fh);

    if (ref($arg) eq "GLOB") {
	$fh = $arg;
    } elsif (ref(\$arg) eq "GLOB") {
	$fh = \*{$arg};
    } else {
	open($fh,"<",$arg)
	    or croak "$arg: open: $!\n";
	binmode($fh);
    }
    $self->SUPER::addfile($fh,@_);
}

1;

__END__

=head1 NAME

Digest::BLAKE3 - Perl extension for the BLAKE3 hash function

=head1 SYNOPSIS

 use Digest::BLAKE3;

 my $hasher = Digest::BLAKE3::->new();

 $hasher->add($data);
 $hasher->addfile($filehandle);

 $hash = $hasher->digest();

=head1 DESCRIPTION

The C<Digest::BLAKE3> module is a Perl wrapper for the C<libblake3>
library providing the BLAKE3 hash function, as found at
L<https://blake3.io/>.

Because building C<libblake3> can get finicky (especially if you
don't have the latest and greatest compiler versions), it is
not included with this module.  You have to build and install it
yourself first.

The module provides the usual C<Digest::*> family object-oriented
interface.

=head1 METHODS

=over

=item $class->new()

=item $hasher->new()

An alias for the new_hash method;

=item $class->new_hash()

=item $hasher->new_hash()

As a class method, creates a new hasher in hash mode.  As an object method,
reinitialises an existing hasher to use hash mode.

=item $class->new_keyed_hash($key)

=item $hasher->new_keyed_hash($key)

As a class method, creates a new hasher in keyed hash mode.  As an object
method, reinitialises an existing hasher to use keyed hash mode.

The key must be a 32-byte string.

=item $class->new_derive_key($context)

=item $hasher->new_derive_key($context)

As a class method, creates a new hasher in key derivation mode.  As an
object method, reinitialises an existing hasher to use key derivation mode.

The context is a byte string of any length.

=item $hasher->clone()

Returns a new hasher with the same state, mode, and output size
as the original.

=item $hasher->reset()

Resets an existing hasher without changing its mode.

=item $hasher->add($bytes, ...)

Updates the hasher state with each of the given byte strings.

=item $hasher->addfile($filehandle)

Updates the hasher with all the bytes read from the given file handle
until end-of-file.

=item $hasher->addfile($filename)

Opens the named file in binary mode and updates the hasher
with the contents.

=item $hasher->digest()

Returns the final hash value as a byte string and resets the hasher.

=item $hasher->hexdigest()

Returns the final hash value as a hexadecimal text string and resets
the hasher.

=item $hasher->b64digest()

Returns the final hash value as a base-64 text string and resets
the hasher.

=item $hasher->hashsize()

=item $hasher->hashsize($hashsize)

Returns the current output hash size and optionally sets a new
output hash size.  The value is given in bits and must be a positive
multiple of 8.  The default is 256 bits.

=item $hasher->mode()

Returns the current mode as a string; one of "hash", "keyed_hash",
or "derive_key".

=back

=head1 AUTHOR

Bo Lindbergh <blgl@stacken.kth.se>

=cut
