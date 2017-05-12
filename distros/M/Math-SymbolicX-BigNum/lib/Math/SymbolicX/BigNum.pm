package Math::SymbolicX::BigNum;

use 5.006;
use strict;
use warnings;
use Carp;

require Math::BigInt;
require Math::BigRat;
require Math::BigFloat;

our $VERSION = '0.02';

use Math::SymbolicX::ParserExtensionFactory (
    bigint => sub {
        my $argstring = shift;
        return Math::Symbolic::Constant->new( Math::BigInt->new($argstring) );
    },
    bigrat => sub {
        my $argstring = shift;
        return Math::Symbolic::Constant->new( Math::BigRat->new($argstring) );
    },
    bignum => sub {
        my $argstring = shift;
        if ( $argstring =~ /\// ) {
            return Math::Symbolic::Constant->new(
                Math::BigRat->new($argstring) );
        }
        else {
            return Math::Symbolic::Constant->new(
                Math::BigFloat->new($argstring) );
        }
    },
    bigfloat => sub {
        my $argstring = shift;
        return Math::Symbolic::Constant->new( Math::BigFloat->new($argstring) );
    },
);

1;
__END__

=head1 NAME

Math::SymbolicX::BigNum - Big number support for the Math::Symbolic parser

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  use Math::SymbolicX::BigNum;
  
  my $formula = parse_from_string('bignum(1000000000000000000000000000) + 1');
  print $formula->value();
  # prints 1000000000000000000000000001 instead of the incaccurate 1e+27

=head1 DESCRIPTION

This module adds big number support to Math::Symbolic. It does so by
extending the parser of the Math::Symbolic module (that is,
the one stored in $Math::Symbolic::Parser) with certain special functions
that create arbitrary precision constants. (Math::Symbolic::Variable objects
have been able to contain arbitrary precision objects since the very
beginning.)

=head2 MOTIVATION

All constants in strings that are parsed by Math::Symbolic::Parser are
converted to Math::Symbolic::Constant objects holding the value
associated to the constant in an ordinary Perl Scalar by default.
Unfortunately, that means if you get a really big integer or a fraction,
you are subject to the precision limitations of the underlying floating point
variables.

On the other hand, Tels wrote the formidable Math::Big* modules to make
arbitrary precision calculations possible, so since the Math::Symbolic::Scalar
objects can hold any object, you can build your trees by hand using
Math::Big* objects instead of Perl Scalars for the value of the constants.
But since the Math::Symbolic::Parser is by far the most convenient interface
to Math::Symbolic, there had to be a reasonably simple way of introducing
Math::Big* support to the parser. So here goes.

=head2 USAGE

In order to get arbitrary precision constants in Math::Symbolic trees from
the parser, you just load this extension module and wrap any of the
hereafter listed functions around any constants that are or may become big
(or small).

The aformentioned functions are C<bigint(...)>, C<bigrat(...)>,
C<bigfloat(...)> and C<bignum(...)> with bignum playing a special role.
Obviously, C<bigint(...)>, C<bigrat(...)> and C<bigfloat(...)> return
objects of the associated type (Math::BigInt, ...). C<bignum(...)>, however,
returns a Math::BigRat if the argument conains a slash and a Math::BigFloat
otherwise.

Example usage:

  print parse_from_string('bigrat(1) / 9 + 2*3 - bigrat(2/7)')->simplify();

This prints '367/63', but if you were to leave the second call to C<bigrat()>
out, it would print '26214285714285713/4500000000000000' because the
'2/7' would be calculated before they were added to the Math::BigRat object
preventing it from working its magic.

=head1 AUTHOR

Copyright (C) 2004 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

You may contact the author at symbolic-module at steffen-mueller dot net

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

Also have a look at L<Math::Symbolic>,
and at L<Math::Symbolic::Parser>

Refer to L<Math::SymbolicX::ParserExtensionFactory> for the implementation
details.

=cut
