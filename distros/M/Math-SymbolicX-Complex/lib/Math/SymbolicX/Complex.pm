package Math::SymbolicX::Complex;

use 5.006;
use strict;
use warnings;
use Math::Symbolic;
use Carp qw/confess cluck/;

require Math::Complex;

package Math::Symbolic::Parser;
use Math::Complex;

package Math::SymbolicX::Complex;

our $VERSION = '1.01';

# Regular expression for floating point numbers.
# Stolen from Math::Complex version 1.34, but since this will be released
# under the same (artistic/perl) license, that should be alright.
my $floatingpoint = qr'\s*([\+\-]?(?:(?:(?:\d+(?:_\d+)*(?:\.\d*(?:_\d+)*)?|\.\d+(?:_\d+)*)(?:[eE][\+\-]?\d+(?:_\d+)*)?)))';

my $opregex = qr/[^0-9e\-\+\*\/\.]/;


use Math::SymbolicX::ParserExtensionFactory (
    complex => sub {
        my $argstring = shift;
	$argstring = _parse_args($argstring);
	my ($re, $im) = split(/,/, $argstring, 2);

	# get numeric representations
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse."
		if $re =~ $opregex or $im =~ $opregex;
	$re = eval $re;
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error Msg.: $@)" if $@;
	$im = eval $im;
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error Msg.: $@)" if $@;

	my $object;
	eval {
		$object = Math::Complex->make($re, $im);
	};
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error msg.: '$@')" if $@;
        return Math::Symbolic::Constant->new($object);
    },
    polar => sub {
        my $argstring = shift;
	$argstring = _parse_args($argstring);
	my ($r, $arg) = split(/,/, $argstring, 2);
	
	# get numeric representations
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse."
		if $r =~ $opregex or $arg =~ $opregex;
	$r = eval $r;
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error Msg.: $@)" if $@;
	$arg = eval $arg;
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error Msg.: $@)" if $@;

	my $object;
	eval {
		$object = Math::Complex->emake($r, $arg);
	};
	confess "Could not generate Math::Complex object from '$argstring' "
		."in Math::Symbolic parse. (Error msg.: '$@')" if $@;

        return Math::Symbolic::Constant->new($object);
    },
);


sub _parse_args {
	my $str = shift;
	$str =~ s/\s+//g;
	$str =~ s{pi}{Math::Symbolic::ExportConstants::PI}e;
	return $str;
# We tried to be very smart at first, but it turned out to be buggy:
#	$str =~ s{
#		((?:$floatingpoint)?)pi
#	}
#	{
#		warn "$1";
#		defined($1) && $1 ne ''
#		? $1 * Math::Symbolic::ExportConstants::PI
#		: Math::Symbolic::ExportConstants::PI
#	}e;
#	return $str;
}

1;
__END__

=head1 NAME

Math::SymbolicX::Complex - Complex number support for the Math::Symbolic parser

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  use Math::SymbolicX::Complex;
  
  my $formula = parse_from_string('3 * complex(3,2)^2 + polar(1, pi/2)');
  print $formula->value();
  # prints '14.9999999997949+37i'
  # (blame the inaccuracy on the floating point representation of "pi")

=head1 DESCRIPTION

This module adds complex number support to Math::Symbolic. It does so by
extending the parser of the Math::Symbolic module (that is,
the one stored in $Math::Symbolic::Parser) with certain special functions
that create complex constants. (Math::Symbolic::Variable objects
have been able to contain complex number objects since the very
beginning.)

=head2 MOTIVATION

All constants in strings that are parsed by Math::Symbolic::Parser are
converted to Math::Symbolic::Constant objects holding the value
associated to the constant in an ordinary Perl Scalar by default.
Unfortunately, that means you are limited to real floating point numbers.

On the other hand, there's the formidable Math::Complex module that gives
complex number support to Perl. Since the Math::Symbolic::Scalar
objects can hold any object, you can build your trees by hand using
Math::Complex objects instead of Perl Scalars for the value of the constants.
But since the Math::Symbolic::Parser is by far the most convenient interface
to Math::Symbolic, there had to be a reasonably simple way of introducing
Math::Complex support to the parser. So here goes.

=head2 USAGE

In order to complex number constants in Math::Symbolic trees from
the parser, you just load this extension module and wrap any of the
functions listed hereafter around any constants that are complex in nature.

The aforementioned functions are C<complex()> and C<polar()>.
C<complex(RE, IM)> takes a real portion and an imaginary portion of the
complex number as arguments. That means, it uses the
C<Math::Complex->make(RE, IM)> method to create the Math::Complex
objects. Similarily, C<polar()> uses the C<Math::Complex->emake(R, ARG)>
syntax provided by Math::Complex. (Polar notation is r*e^(i*arg). It is
equivalent to the C<x+i*y> notation because it also covers the whole complex
plane.)

There are some usability extensions to the simple C<complex(RE, IM)> and
C<polar(R, ARG)> notations: You can use the basic operators
('+', '-', '*', '/', and '**') and the symbolic constant 'pi' in the
expressions for RE, IM, R, and ARG. That means C<polar(1, pi/2)> should
be translated to C<polar(1, 1.5707963267949)> internally.

Note, however,
that the floating point representation of pi used in this module is
far from exact. So, instead of yielding C<0+i> as a result, the above example
will be C<-3.49148336110938e-015+i>. Of course, C<-3.49148336110938e-015>
is as close to a real zero as you'll get, but testing for equality with
the C<==> operator will break.

=head1 AUTHOR

Copyright (C) 2004-2007, 2013 Steffen Mueller

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

You should definately be familiar with L<Math::Complex> before you start
using this module because the objects that are returned
from C<$formula->value()> calls are Math::Complex objects.

Also have a look at L<Math::Symbolic>,
and at L<Math::Symbolic::Parser>

Refer to L<Math::SymbolicX::ParserExtensionFactory> for the implementation
details.

=cut
