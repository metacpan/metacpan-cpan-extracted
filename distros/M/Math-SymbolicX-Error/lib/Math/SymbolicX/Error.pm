package Math::SymbolicX::Error;

our $VERSION = '1.01';

use 5.006;
use strict;
use warnings;
use Number::WithError;
use Math::Symbolic;
use Carp qw/confess cluck/;


use Math::SymbolicX::ParserExtensionFactory (
	'error' => sub {
		my $argstring = shift;

		my $num;
		eval { $num = Number::WithError->new($argstring); };
		confess "Could not generate Number::WithError object from '$argstring' "
			."in Math::Symbolic parse."
		if $@ or not defined $num;

        return Math::Symbolic::Constant->new($num);
    },
	'error_big' => sub {
		my $argstring = shift;

		my $num;
		eval { $num = Number::WithError->new_big($argstring); };
		confess "Could not generate Number::WithError object with Math::BigFloat representation from '$argstring' "
			."in Math::Symbolic parse."
		if $@ or not defined $num;

        return Math::Symbolic::Constant->new($num);
    },
);


1;
__END__

=head1 NAME

Math::SymbolicX::Error - Parser extension for dealing with numeric errors

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  use Math::SymbolicX::Error;
  
  # Inlined Number::WithError declarations: 
  my $formula = parse_from_string('3 * error(3 +/- 0.2)^2 + error(1 +/- 0.1)');
  print $formula->value();
  # prints '2.80e+01 +/- 3.6e+00'
  
  # High precision support using Math::BigFloat
  my $high_precision = parse_from_string('3 * error_big(3e-12 +/- 0.2e-12');
  print $high_precision->value();
  # prints '9.00e-12 +/- 6.0e-13'

=head1 DESCRIPTION

This module adds numeric error (or uncertainty) support to the Math::Symbolic
parser. It does so by extending the parser grammar of the Math::Symbolic
module (that is, the one stored in $Math::Symbolic::Parser) with certain
special functions that create constants as L<Number::WithError> objects.
(Math::Symbolic::Variable objects have been able to contain objects since
the very beginning.)

=head2 MOTIVATION

All constants in strings that are parsed by Math::Symbolic::Parser are
converted to Math::Symbolic::Constant objects holding the value
associated to the constant in an ordinary Perl Scalar by default.
Unfortunately, that means you are limited to real floating point numbers.

On the other hand, it might be necessary to attach a certain error to
a number and calculate using error propagation. Math::SymbolicX::Error
helps making this process more opaque. Since the Math::Symbolic::Constant
objects can hold any object, you can build your trees by hand using
Math::Complex objects instead of Perl Scalars for the value of the constants.
But since the Math::Symbolic::Parser is by far the most convenient interface
to Math::Symbolic, there had to be a reasonably simple way of introducing
Number::WithError support to the parser. So here goes.

=head2 USAGE

In order to numeric constants with errors in Math::Symbolic trees from
the parser, you just load this extension module and wrap any of the
functions listed hereafter around any constants that have an associated error.

The aforementioned functions are C<error()> and C<error_big()>.
C<error()> turns its arguments into a Number::WithError object which is
injected into the Math::Symbolic tree at the point in the parse tree at which
the C<error()> function was found.

Similarily, C<error_big()> creates a Number::WithError object but with
Math::BigFloat support. That is, arbitrary precision.

=head1 AUTHOR

Steffen Mueller, E<lt>symbolic-module at steffen-mueller dot net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

You should definately be familiar with L<Number::WithError> before you start
using this module because the objects that are returned
from C<$formula->value()> calls are Number::WithError objects.

Also have a look at L<Math::Symbolic>,
and at L<Math::Symbolic::Parser>

Refer to L<Math::SymbolicX::ParserExtensionFactory> for the implementation
details.

Other parser extensions include big- and complex number support:
L<Math::SymbolicX::BigNum>, L<Math::SymbolicX::Complex>

=cut
