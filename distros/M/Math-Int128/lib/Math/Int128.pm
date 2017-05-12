package Math::Int128;

use strict;
use warnings;

# The "our $VERSION" bit needs to be at the beginning of the line for the
# benefit of the RewriteVersion plugin.
BEGIN {
our $VERSION = '0.22';
require XSLoader;
XSLoader::load('Math::Int128', $VERSION);
}

use Math::Int64 0.51;

use constant MAX_INT128  => string_to_int128 ( '0x7fff_ffff_ffff_ffff_ffff_ffff_ffff_ffff');
use constant MIN_INT128  => string_to_int128 ('-0x8000_0000_0000_0000_0000_0000_0000_0000');
use constant MAX_UINT128 => string_to_uint128( '0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff');

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( ctors => [qw( int128 uint128
                                   string_to_int128
                                   string_to_uint128 )],
                     pack  => [qw( int128_to_number
                                   int128_to_hex
                                   net_to_int128
                                   int128_to_net
                                   native_to_int128
                                   int128_to_native
                                   uint128_to_number
                                   uint128_to_hex
                                   net_to_uint128
                                   uint128_to_net
                                   native_to_uint128
                                   uint128_to_native )],
                     op    => [qw( int128_set
                                   int128_inc
                                   int128_dec
                                   int128_add
                                   int128_sub
                                   int128_mul
                                   int128_pow
                                   int128_div
                                   int128_mod
                                   int128_divmod
                                   int128_neg
                                   int128_not
                                   int128_and
                                   int128_or
                                   int128_xor
                                   int128_left
                                   int128_right
                                   int128_average
                                   uint128_set
                                   uint128_inc
                                   uint128_dec
                                   uint128_add
                                   uint128_sub
                                   uint128_mul
                                   uint128_pow
                                   uint128_div
                                   uint128_mod
                                   uint128_divmod
                                   uint128_not
                                   uint128_and
                                   uint128_or
                                   uint128_xor
                                   uint128_left
                                   uint128_right
                                   uint128_average)],
                   limits  => [qw( MAX_INT128
                                   MIN_INT128
                                   MAX_UINT128 )] );

our @EXPORT_OK = map @$_, values %EXPORT_TAGS;


use overload ( '+' => \&_add,
               '+=' => \&_add,
               '-' => \&_sub,
               '-=' => \&_sub,
               '*' => \&_mul,
               '*=' => \&_mul,
               '**' => \&_pow,
               '**=' => \&_pow,
               '/' => \&_div,
               '/=' => \&_div,
               '%' => \&_remainder,
               '%=' => \&_remainder,
               'neg' => \&_neg,
               '++' => \&_inc,
               '--' => \&_dec,
               '!' => \&_not,
               '~' => \&_bnot,
               '&' => \&_and,
               '|' => \&_or,
               '^' => \&_xor,
               '<<' => \&_left,
               '>>' => \&_right,
               '<=>' => \&_spaceship,
               '>' => \&_gtn,
               '<' => \&_ltn,
               '>=' => \&_gen,
               '<=' => \&_len,
               '==' => \&_eqn,
               '!=' => \&_nen,
               'bool' => \&_bool,
               '0+' => \&_number,
               '""' => \&_string,
               '=' => \&_clone,
               fallback => 1 );

package Math::UInt128;
use overload ( '+' => \&_add,
               '+=' => \&_add,
               '-' => \&_sub,
               '-=' => \&_sub,
               '*' => \&_mul,
               '*=' => \&_mul,
               '**' => \&_pow,
               '**=' => \&_pow,
               '/' => \&_div,
               '/=' => \&_div,
               '%' => \&_remainder,
               '%=' => \&_remainder,
               'neg' => \&_neg,
               '++' => \&_inc,
               '--' => \&_dec,
               '!' => \&_not,
               '~' => \&_bnot,
               '&' => \&_and,
               '|' => \&_or,
               '^' => \&_xor,
               '<<' => \&_left,
               '>>' => \&_right,
               '<=>' => \&_spaceship,
               '>' => \&_gtn,
               '<' => \&_ltn,
               '>=' => \&_gen,
               '<=' => \&_len,
               '==' => \&_eqn,
               '!=' => \&_nen,
               'bool' => \&_bool,
               '0+' => \&_number,
               '""' => \&_string,
               '=' => \&_clone,
               fallback => 1 );

1;

__END__

=encoding UTF-8

=head1 NAME

Math::Int128 - Manipulate 128 bits integers in Perl

=head1 SYNOPSIS

  use Math::Int128 qw(int128);

  my $i = int128(1);
  my $j = $i << 100;
  my $k = int128("1234567890123456789000000");
  print($i + $j * 1000000);

=head1 DESCRIPTION

This module adds support for 128 bit integers, signed and unsigned, to
Perl.

In order to compile this module, your compiler must support one of either the
C<__int128> or C<int __attribute__ ((__mode__ (TI)))> types. Both GCC and
Clang have supported one or the other type for some time, but they may only do
so on 64-bit platforms.

=head2 OSX Caveat

On OSX, the system Perl is compiled with both the "-arch x86_64" and "-arch
i386" flags. When building this module with a Perl like this, we strip the
"-arch i386" flag out, meaning it is only compiled for the 64-bit
architecture. Attempting to use this module while running in 32-bit mode may
lead to brokenness. It's also possible that this will cause other problems
that we cannot foresee.

Note that if you have built your own non-multiarch Perl on OSX then this will
not be an issue.

=head1 API

See L<Math::Int64>. This module provides a similar set of functions,
just C<s/64/128/g> ;-)

Besides that, as object allocation and destruction has been found to
be a bottleneck, an alternative set of operations that use their first
argument as the output (instead of the return value) is also
provided.

They are as follows:

  int128_inc int128_dec int128_add int128_sub int128_mul int128_pow
  int128_div int128_mod int128_divmod int128_and int128_or int128_xor
  int128_left int128_right int128_not int128_neg

and the corresponding C<uint128> versions.

For instance:

  my $a = int128("1299472960684039584764953");
  my $b = int128("-2849503498690387383748");
  my $ret = int128();
  int128_mul($ret, $a, $b);
  int128_inc($ret, $ret); # $ret = $ret + 1
  int128_add($ret, $ret, "12826738463");
  say $ret;

C<int128_divmod> returns both the result of the division and the remainder:

  my $ret = int128();
  my $rem = int128();
  int128_divmod($ret, $rem, $a, $b);

=head1 C API

The module provides a C API that allows to wrap/unwrap int128_t and
uint128_t values from other modules written in C/XS.

It is identical to that provided by L<Math::Int64> so read the
documentation there in order to know how to use it.

=head1 TODO

Support more operations as log2, pow, etc.

=head1 BUGS AND SUPPORT

The C API feature is experimental.

This module requires 128bit integer support from the C
compiler. Currently only gcc 4.4 and later are supported. If you have
a different compiler that also supports 128bit integers get in touch
with me in order to have it supported.

You can send me bug reports by email to the address that appears below
or use the CPAN RT bug tracking system available at
L<http://rt.cpan.org>.

The source for the development version of the module is hosted at
GitHub: L<https://github.com/salva/p5-Math-Int128>.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

=head1 SEE ALSO

L<Math::Int64>, L<Math::GMP>, L<Math::GMPn>.

L<http://perlmonks.org/?node_id=886488>.

=head1 COPYRIGHT AND LICENSE

Copyright E<copy> 2007, 2009, 2011-2015 by Salvador Fandiño (sfandino@yahoo.com)

Copyright E<copy> 2014-2015 by Dave Rolsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
