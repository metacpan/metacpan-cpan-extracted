package FFI::Me;

use strict;
use warnings;
use FFI::Raw ();

$FFI::Me::VERSION = '0.01';

sub import {
    my $caller = caller();
    no strict 'refs';    ## no critic
    *{ $caller . '::ffi' } = \&ffi;
    return;
}

sub ffi {
    my ( $name, %args ) = @_;

    $args{sym} = $name       if !exists $args{sym} || !defined $args{sym};
    $args{rv}  = ffi::void() if !exists $args{rv}  || !defined $args{rv};
    $args{arg} = []          if !exists $args{arg};

    my $code = FFI::Raw->new( $args{lib}, $args{sym}, $args{rv}, @{ $args{arg} } );

    my $caller = caller();
    no strict 'refs';    ## no critic
    *{ $caller . '::' . $name } = sub { shift if $args{method}; return $code->call(@_) };

    return;
}

*ffi::void   = \&FFI::Raw::void;
*ffi::int    = \&FFI::Raw::int;
*ffi::uint   = \&FFI::Raw::uint;
*ffi::short  = \&FFI::Raw::short;
*ffi::ushort = \&FFI::Raw::ushort;
*ffi::long   = \&FFI::Raw::long;
*ffi::ulong  = \&FFI::Raw::ulong;
*ffi::int64  = \&FFI::Raw::int64;
*ffi::uint64 = \&FFI::Raw::uint64;
*ffi::char   = \&FFI::Raw::char;
*ffi::uchar  = \&FFI::Raw::uchar;
*ffi::float  = \&FFI::Raw::float;
*ffi::double = \&FFI::Raw::double;
*ffi::str    = \&FFI::Raw::str;
*ffi::ptr    = \&FFI::Raw::ptr;

1;

__END__

=encoding utf-8

=head1 NAME

FFI::Me - Turn foreign functions into perl functions or methods without writing XS.

=head1 VERSION

This document describes FFI::Me version 0.01

=head1 SYNOPSIS

    use FFI::Me;

    ffi puts => (
        rv  => ffi::int,
        arg => [ffi::str],
    );

    puts("Say what!");


Uses in an OO package with a method name that differs from the symbol in the library:
    
    ffi cosine => (
        lib => 'libm.so'
        rv  => ffi::double,
        arg => [ffi::double],
        sym => 'cos',
        method => 1,
    );

Then later when we have an object:

    say $obj->cosine(2.0);

Note: To make your code more portable you could do something like:

    lib => $^O eq 'darwin' ? 'libm.dylib' : 'libm.so',

or use something like L<FFI::CheckLib>.

See </TODO>.

=head1 DESCRIPTION

libffi (low-level FFI via L<FFI::Raw> in this case) is a really neat way to get access to foreign functions from inside perl.

This module encapsulates the common task of creating the interface via the low-level FFI and then making a higher-level function or method to wrap it.

The simple syntax is the sugary style prefered by most MOPish code.

=head1 INTERFACE 

=head2 ffi

Imported automatically.

Syntax: ffi NAME => (OPTIONS);

Creates a function or method called "NAME" from a foreign function desribed via NAME and OPTIONS.

See L</SYNOPSIS> for examples.

The options are as follows:

=over 4

=item * lib

The library that contains the symbol we are interested in.

Default: undef (i.e. search in the main program for the foreign function)

=item * rv

The type for the return value of the symbol we are interested in.

Default: ffi::void

=item * arg

An array ref of types of the arguments taken by the symbol we are interested in.

Default: empty list

=item * sym

The name of the foreign function symbol in our lib. Useful when you want your perl function or method to be a different name than the foreign function symbol you are interfacing with.

Default: The NAME passed to ffi().

=item * method

Boolean. If true, it will create the symbol as a method instead of a function.

Default: false

=back

=head2 Types

Each type has a function that will return the type suitable for “rv” and “arg”.

We use the ffi:: name space for these functions to avoid importing them while still keeping them short.

=head3 ffi::void

=head3 ffi::int

=head3 ffi::uint

=head3 ffi::short

=head3 ffi::ushort

=head3 ffi::long

=head3 ffi::ulong

=head3 ffi::int64

=head3 ffi::uint64

=head3 ffi::char

=head3 ffi::uchar

=head3 ffi::float

=head3 ffi::double

=head3 ffi::str

=head3 ffi::ptr

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

The underlying low-level library throws an exception when it can’t do what we’re asking it to.

=head1 DEPENDENCIES

L<FFI::Raw>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ffi-me@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 TODO

Possibly some library lookup ability to allow for things like C<lib => 'libm'> witout needing to C<$^O eq 'darwin' ? 'libm.dylib' : 'libm.so'>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
