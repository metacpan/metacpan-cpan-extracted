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

our $VERSION = '0.01';
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
sub argsparse {
    my ($data, $len, $A, $B) = @_;

    croak "data not defined" unless defined $data;
    croak "Invalid length specified" unless defined $len and $len > 0;

    my $C = 10 ** $len;

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
    $B = Math::BigInt->bmodinv($A, $C) unless defined $B;
    croak "Invalid B value for such length and A" if Math::BigInt->is_nan($B);

    return ($data, $len, $A, $B, $C);
}

# Calculate hash of number
# args: $number, $length, $A, $B
sub revhash {
    if ($UNSAFE) {
        $_[4] = 10 ** $_[1];
    } else {
        @_ = argsparse @_;
    }

    sprintf "%0$_[1]d", $_[0] * $_[2] % $_[4];
}

# Calculate original number of hash
# args: $hash, $length, $A, $B
sub revunhash {
    if ($UNSAFE) {
        $_[4] = 10 ** $_[1];
    } else {
        @_ = argsparse @_;
    }

    $_[0] * $_[3] % $_[4];
}

# OO alias
sub hash { @_ = ($_[1], @{$_[0]}); goto &revhash }

# OO alias
sub unhash { @_ = ($_[1], @{$_[0]}); goto &revunhash }

# OO ctor
# args: $class, $length, $A, $B
sub new {
    my $obj;

    (undef, @{$obj}) = argsparse(1, @_[1..3]);

    bless $obj, $_[0];
}

1; # End of Math::Revhash

__END__

=pod

=encoding utf8

=head1 NAME

Math::Revhash - Reversible hashes library

=head1 SYNOPSIS

    use Math::Revhash qw( revhash revunhash );

    # OO style
    my $revhash = Math::Revhash->new( $length, $A, $B );
    my $hash = $revhash->hash( $number );
    my $number = $revhash->unhash( $hash );

    # Procedural style
    my $hash = revhash( $number, $length, $A, $B );
    my $number = revunhash( $hash, $length, $A, $B );

    # See UNSAFE MODE
    $Math::Revhash::UNSAFE = 1;

=head1 DESCRIPTION

This module is intended for fast and lightweight numbers reversible hashing.
Say there are millions of entries inside RDBMS and each entry identified with
sequential primary key.
Sometimes we want to expose this key to users, i.e. in case it is a session ID.
Due to multiple reasons it could be a good idea to hide from the outer world
that those session IDs are just a generic sequence of integers.
This module will perform fast, lightweight and reversible translation between
simple sequence C<1, 2, 3, ...> and something like C<3287, 8542, 1337, ...>
without need for hash-table lookups, large memory storage and any other
expensive things.

So far, this module is only capable of translating positive non-zero integers.
To use the module you can either choose one of existing hash lengths: 1..9, or
specify any positive C<$length> with non-default C<$A> parameter.
In any case C<data> for hashing should not exceed predefined hash length.
C<$B> parameter could also be specified to avoid extra modular inverse
calculation.

=head1 SUBROUTINES/METHODS

=head2 revhash($number, $length, $A, $B)

=over 4

=item C<$number> --

the number to be hashed.

=item C<$length> --

required hash length.

=item C<$A> --

I<(optional for pre-defined lengths)> a parameter of hash function.
There are some hard-coded C<$A> values for pre-defined lengths.
You are free to specify any positive C<$A> to customize the function.
It is recommended to choose only primary numbers for C<$A> to avoid possible
collisions.
C<$A> should not be too short or too huge digit number.
It's recommended to start with any primary number close to C<10 ** ($len + 1)>.
You are encouraged to play around it on your own.

=item C<$B> --

I<(optional)> modular inverse of C<$A>:

    $B = Math::BigInt->bmodinv($A, 10 ** $len)

=back

=head2 revunhash($hash, $length, $A, $B)

=over 4

=item C<$hash> --

hash value that should be translated back to a number.

=back

=head2 hash($number)

alias for revhash.

=head2 unhash($hash)

alias for revunhash.

=head2 new($length, $A, $B)

object constructor that stores C<$length>, C<$A>, and C<$B> in the object.

=head1 UNSAFE MODE

Arguments parsing and parameters auto-computing takes some time.
There is an UNSAFE mode to speed up the whole process (see SYNOPSIS).
In this mode all arguments becomes mandatory.
Use this mode with extra caution.

=head1 AUTHOR

Sergei Zhmylev, C<< <zhmylove@cpan.org> >>

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

