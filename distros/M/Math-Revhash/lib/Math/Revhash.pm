#!/usr/bin/perl
#made by: KorG
# vim: sw=4 ts=4 et cc=79 :

package Math::Revhash;

use 5.008;
use strict;
use warnings FATAL => 'all';
use Carp;
use Exporter 'import';
use Math::BigInt;

our $VERSION = '0.03';
$VERSION =~ tr/_//d;

our @EXPORT_OK = qw( revhash revunhash );

# Fast hashing is based on reverse modulo operations. 
# Given HASH = NUMBER * A % C, then NUMBER = HASH * B % C in case of B is
# a modular inverse of A.
# To avoid hash collisions A should be a primary number.

# Pre-defined $A and $B for certain lengths
my $AB = {
    1 => [ 103, 7 ],
    2 => [ 929, 69 ],
    3 => [ 1619, 979 ],
    4 => [ 17027, 9963 ],
    5 => [ 88651, 58851 ],
    6 => [ 894407, 991543 ],
    7 => [ 16006519, 8315079 ],
    8 => [ 130067887, 91167823 ],
    9 => [ 2700655597, 882024933 ],
};

# See UNSAFE MODE
our $UNSAFE = 0;

# Parse and prepare arguments
# This function is used by revhash, revunhash and new subroutines
sub _argsparse {
    my ($data, $len, $A, $B, $C) = @_;

    croak "data not defined" unless defined $data;
    croak "Invalid length specified" unless defined $len and $len > 0;

    if (defined $C) {
        croak "Hash C value is invalid" unless $C > 0;
    } else {
        $C = 10 ** $len;
    }

    croak "data ($data) is out of range" unless $data > 0 and $data < $C;

    if (defined $A) {
        croak "Hash A value is invalid" unless $A > 0;
    } else {
        $A = $AB->{$len}->[0];
    }
    croak "Hash A value is undefined" unless defined $A;

    if (defined $B) {
        croak "Hash B value is invalid" unless $B > 0;
    } else {
        $B = $AB->{$len}->[1];
    }
    $B = Math::BigInt->new($A)->bmodinv($C) unless defined $B;
    croak "Invalid B value for such length and A" if Math::BigInt->is_nan($B);

    return ($data, $len, $A, $B, $C);
}

# Calculate hash of number
# args: $number, $length, $A, $B, $C
sub revhash {
    @_ = _argsparse @_ unless $UNSAFE;

    sprintf "%0$_[1]d", $_[0] * $_[2] % $_[4];
}

# Calculate original number of hash
# args: $hash, $length, $A, $B, $C
sub revunhash {
    @_ = _argsparse @_ unless $UNSAFE;

    $_[0] * $_[3] % $_[4];
}

# OO alias
sub hash { @_ = ($_[1], @{$_[0]}); goto &revhash }

# OO alias
sub unhash { @_ = ($_[1], @{$_[0]}); goto &revunhash }

# OO ctor
# args: $class, $length, $A, $B, $C
sub new {
    my $obj;

    (undef, @{$obj}) = _argsparse(1, @_[1..4]);

    bless $obj, $_[0];
}

1; # End of Math::Revhash

__END__

=pod

=encoding utf8

=head1 NAME

Math::Revhash - Reverse hash computation library

=head1 SYNOPSIS

    use Math::Revhash qw( revhash revunhash );

    # OO style
    my $revhash = Math::Revhash->new( $length, $A, $B, $C );
    my $hash = $revhash->hash( $number );
    my $number = $revhash->unhash( $hash );

    # Procedural style
    my $hash = revhash( $number, $length, $A, $B, $C );
    my $hash = revhash( $number, 5 );
    my $number = revunhash( $hash, $length, $A, $B, $C );

    # See UNSAFE MODE
    $Math::Revhash::UNSAFE = 1;

=head1 DESCRIPTION

This module is intended for fast and lightweight numbers reversible hashing.
Say there are millions of entries inside RDBMS and each entry identified with
sequential primary key.
Sometimes we want to expose this key to users, i.e. in case it is a session ID.
Due to several reasons it could be a good idea to hide from the outer world
that those session IDs are just a generic sequence of integers.
This module will perform fast, lightweight and reversible translation between
simple sequence C<1, 2, 3, ...> and something like C<3287, 8542, 1337, ...>
without need for hash-table lookups, large memory storage and any other
expensive mechanisms.

So far, this module is only capable of translating positive non-zero integers.
To use the module you can either choose one of hash lengths: 1..9,
for which all other parameters are pre-defined, or specify any positive
C<$length> with non-default C<$A> parameter (see below).
In any case C<$number> for hashing should not exceed predefined hash length.
C<$B> and C<$C> parameters could also be specified to avoid extra modular
inverse and power calculation, respectively.

=head1 SUBROUTINES

=head2 revhash

Compute C<$hash = revhash($number, $length, $A, $B, $C)>

=over 4

=item C<$number> is the source number to be hashed.

=item C<$length> is required hash length in digits.

=item C<$A> I<(optional for pre-defined lengths)> is the first parameter of
hash function.

There are some hard-coded C<$A> values for pre-defined lengths.
You are free to specify any positive C<$A> to customize the function.
It is recommended to choose only primary numbers for C<$A> to avoid possible
collisions.
C<$A> should not be too short or too huge digit number.
It is recommended to start with any primary number close to
C<10 ** ($length + 1)>.
You are encouraged to play around it on your own.

=item C<$B> I<(optional)> is the second parameter of hash function.

It is a modular inverse of C<$A> and is
being computed as C<$B = Math::BigInt-E<gt>bmodinv($A, 10 ** $length)> unless
explicitly specified.

=item C<$C> I<(optional)> is the third parameter of hash function.

As our numbers are decimal it is just C<10> to the power of C<$length>:
C<$C = 10 ** $length>.

=back

=head2 revunhash

Compute C<$number = revunhash($hash, $length, $A, $B, $C)>.
It takes the same arguments as C<revhash> besides:

=over 4

=item C<$hash> is hash value that should be translated back to a number.

=back

=head2 hash

Just an object oriented alias for revhash: C<$hash = $obj-E<gt>hash($number)>.
All the hash function parameters will be taken from the object itself.

=head2 unhash

Just an object oriented alias for revunhash:
C<$number = $obj-E<gt>unhash($hash)>.
All the hash function parameters will be taken from the object itself.

=head2 new

C<$obj = Math::Revhash-E<gt>new($length, $A, $B, $C)> is an object constructor
that will firstly check and vivify all the arguments and store them inside
new object.

=head1 UNSAFE MODE

Arguments parsing and parameters auto-computing takes some time thus sometimes
it would be preffered to avoid this phase on every translation operation.
There is an UNSAFE mode to speed up the whole process (see SYNOPSIS).
In this mode all arguments become mandatory on C<revhash/revunhash> calls.
You can either use OO style and still imply and check arguments on object
creation, or use procedural style and specify each argument on every call.
Use this mode with extra caution.

=head1 AUTHOR

Sergei Zhmylev, C<E<lt>zhmylove@cpan.orgE<gt>>

=head1 BUGS

Please report any bugs or feature requests to official GitHub page at
L<https://github.com/zhmylove/math-revhash>.
You also can use official CPAN bugtracker by reporting to
C<bug-math-revhash at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Revhash>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Sergei Zhmylev.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

