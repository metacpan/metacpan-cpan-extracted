
=encoding utf8

=head1 NAME

Math::Symbolic::Parser - Parse strings into Math::Symbolic trees

=head1 SYNOPSIS

  use Math::Symbolic::Parser;
  my $parser = Math::Symbolic::Parser->new();
  $string =~ s/\s+//g;
  my $tree = $parser->parse($string);
  
  # or better:
  use Math::Symbolic;
  my $tree = Math::Symbolic->parse_from_string($string);

=head1 DESCRIPTION

This module contains the parsing routines used by Math::Symbolic to
parse strings into Math::Symbolic trees. Usually, you will want
to simply use the Math::Symbolic->parse_from_string() class method
instead of this module directly. If you do use this module directly,
however, make sure to remove any whitespace from your input string.

=head2 NOTE

With version 0.501 of Math::Symbolic, an experimental, new parser is
introduced, but it is not enabled by default. The new parser is based
on Parse::Yapp instead of Parse::RecDescent and comes with an at least
ten fold speed increase. However, it has not been available for a long
time and is not as well tested. 
Since version 2.00 of the Math::SymbolicX::ParserExtensionFactory module,
it's possible to extend Yapp parsers.

B<At some point in the future the Yapp-based parser will become the
default!> It is suggested you test your code against it before that.
Code that uses the RecDescent based parser's C<Extend> method may
fail!

Until then, you need to load it by hand as follows:

  $Math::Symbolic::Parser = Math::Symbolic::Parser->new(
    implementation=>'Yapp'
  );

This replaces the default Math::Symbolic parser with an instance of the
new Yapp parser.

=head2 STRING FORMAT

The parser has been designed to parse strings that are reminiscient of
ordinary algebraic expressions including the standard arithmetic infix
operators such as multiplication. Many functions such as a rather
comprehensive set of trigonometric functions are parsed in prefix form
like 'sin(expression)' or 'log(base, expression)'. Unknown identifiers starting with a letter and containing only letters, digits, and underscores are
parsed as variables. If these identifiers are followed by parenthesis
containing a list of identifiers, the list is parsed as the signature of
the variable. Example: '5*x(t)' is parsed as the product of the constant five
and the variable 'x' which depends on 't'. These dependencies are
important for total derivatives.

The supported builtin-functions are listed in the documentation for
Math::Symbolic::Operator in the section on the new() constructor.

=head2 EXTENSIONS

In version 0.503, a function named C<exp(...)> is recognized and
transformed into C<e^(...)> internally. In version 0.506, a function
named C<sqrt(...)> was added which is transformed into C<(...)^0.5>.
Version 0.511 added support for the typical C<f'(x)> syntax for
derivatives. For details, refer to the section on parsing
derivatives below.

=head2 EXAMPLES

  # An example from analytical mechanics:
  my $hamilton_function =
          Math::Symbolic->parse_from_string(
            'p_q(q, dq_dt, t) * dq_dt(q, t) - Lagrange(q, p_q, t)'
          );

This parses as "The product
of the generalized impulse p_q (which is a function of the generalized
coordinate q, its derivative, and the time) and the derivative of the
generalized coordinate dq_dt (which depends on q itself and the time).
This term minus the Lagrange Function (of q, the impulse, and the time)
is the Hamilton Function."

Well, that's how it parses in my head anyway. The parser will generate a tree
like this:

  Operator {
    type     => difference,
    operands => (
                  Operator {
                    type     => product,
                    operands => (
                                  Variable {
                                    name         => p_q,
                                    dependencies => q, dq_dt, t
                                  },
                                  Variable {
                                     name         => dq_dt,
                                     dependencies => q, t
                                  }
                    )
                  },
                  Variable {
                    name         => Lagrange,
                    dependencies => q, p_q, t
                  }
                )
  }

Possibly a simpler example would be 'amplitude * sin(phi(t))' which
descibes an oscillation. sin(...) is assumed to be the sine function,
amplitude is assumed to be a symbol / variable that doesn't depend on any
others. phi is recognized as a variable that changes over time (t). So
phi(t) is actually a function of t that hasn't yet been specified.
phi(t) could look like 'omega*t + theta' where strictly speaking,
omega, t, and theta are all symbols without dependencies. So omega and theta
would be treated as constants if you derived them in respect to t.
Figuratively speaking, omega would be a frequency and theta would be a
initial value.

=head2 PARSING DERIVATIVES

The traditional way of specifying a derivative for parsing was
C<partial_derivative(EXPRESSION, VARIABLE)> where C<EXPRESSION>
can be any valid expression and C<VARIABLE> is a variable name.
The syntax denotes a partial derivative of the expression with respect
to the variable. The same syntax is available for total derivatives.

With version 0.511, a new syntax for specifying partial derivatives
was added to the parser(s). C<f'(x)> denotes the first partial
derivative of C<f> with respect to C<x>. If C<(x)> is omitted,
C<f'> defaults to using C<x>. C<f''(a)> is the second order partial
derivative with respect to C<a>. If there are multiple variables
in the parenthesis, a la C<f'(b, a)>, the first variable is
used for the derivatives.

=head2 EXPORT

None by default.

=head1 CLASS DATA

While working with this module, you might get into the not-so-convient position
of having to debug the parser and/or its grammar. In order to make this
possible, there's the $DEBUG package variable which, when set to 1, makes
the parser warn which grammar elements are being processed. Note, however,
that their order is bottom-up, not top-down.

=cut

package Math::Symbolic::Parser;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Symbolic::ExportConstants qw/:all/;

#use Parse::RecDescent;
my $Required_Parse_RecDescent = 0;

our $VERSION = '0.612';
our $DEBUG   = 0;

# Functions that are parsed and translated to specific M::S trees
# *by the parser*.
our %Parser_Functions = (
    'exp' => sub {
        my $func = shift;
        my $arg = shift;
        return Math::Symbolic::Operator->new(
            '^',
            Math::Symbolic::Constant->euler(),
            $arg
        );
    },
    'sqrt' => sub {
        my $func = shift;
        my $arg = shift;
        return Math::Symbolic::Operator->new(
            '^',
            $arg,
            Math::Symbolic::Constant->new(0.5)
        );
    },
);

our $Grammar = <<'GRAMMAR_END';
  parse: expr /^\Z/
            {
              $return = $item[1]
            }
       | // {undef}

  expr: addition
            {
              #warn 'expr ' if $Math::Symbolic::Parser::DEBUG;
              $item[1]
            }

  addition: <leftop:multiplication add_op multiplication>
            {
              #warn 'addition '
              #  if $Math::Symbolic::Parser::DEBUG;
              if (@{$item[1]} == 1) {
                $item[1][0]
              }
              else {
                my @it = @{$item[1]};
                my $tree = shift @it;
                while (@it) {
                  $tree = Math::Symbolic::Operator->new(
                    shift(@it), $tree, shift(@it)
                  );
                }
                $tree;
              }
            }

  add_op: '+'
        | '-'

  multiplication: <leftop:exp mult_op exp>
            {
              #warn 'multiplication '
              #  if $Math::Symbolic::Parser::DEBUG;
              if (@{$item[1]} == 1) {
                $item[1][0]
              }
              else {
                my @it = @{$item[1]};
                my $tree = shift @it;
                while (@it) {
                  $tree = Math::Symbolic::Operator->new(
                    shift(@it), $tree, shift(@it)
                  );
                }
                $tree;
              }
            }

  mult_op: '*'
         | '/'


  exp: <rightop:factor '^' factor>
            {
              #warn 'exp ' if $Math::Symbolic::Parser::DEBUG;
              if (@{$item[1]} == 1) {
                $item[1][0]
              }
              else {
                my @it = reverse @{$item[1]};
                my $tree = shift @it;
                while (@it) {
                  $tree = Math::Symbolic::Operator->new(
                    '^', shift(@it), $tree
                  );
                }
                $tree;
              }
            }

  factor: /(?:\+|-)*/ number
            {
              #warn 'unary_n '
              #  if $Math::Symbolic::Parser::DEBUG;
              if ($item[1]) {
                my @it = split //, $item[1];
                my $ret = $item[2];
                foreach (grep {$_ eq '-'} @it) {
                  $ret = Math::Symbolic::Operator->new('neg',$ret);
                }
                $ret
              }
              else {
                $item[2]
              }
            }

         | /(?:\+|-)*/ function
            {
              #warn 'unary_f '
              #  if $Math::Symbolic::Parser::DEBUG;
              if ($item[1]) {
                my @it = split //, $item[1];
                my $ret = $item[2];
                foreach (grep {$_ eq '-'} @it) {
                  $ret = Math::Symbolic::Operator->new('neg',$ret);
                }
                $ret
              }
              else {
                $item[2]
              }
            }

         | /(?:\+|-)*/ variable
            {
              #warn 'unary_v '
              #  if $Math::Symbolic::Parser::DEBUG;
              if ($item[1]) {
                my @it = split //, $item[1];
                my $ret = $item[2];
                foreach (grep {$_ eq '-'} @it) {
                  $ret = Math::Symbolic::Operator->new('neg',$ret);
                }
                $ret
              }
              else {
                $item[2]
              }
            }

          | /(?:\+|-)*/ '(' expr ')'
            {
              #warn 'unary_expr '
              #  if $Math::Symbolic::Parser::DEBUG;
              if ($item[1]) {
                my @it = split //, $item[1];
                my $ret = $item[3];
                foreach (grep {$_ eq '-'} @it) {
                  $ret = Math::Symbolic::Operator->new('neg',$ret);
                }
                $ret
              }
              else {
                $item[3]
              }
            }

  number:        /([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?/
            {
              #warn 'number '
              #  if $Math::Symbolic::Parser::DEBUG;
              Math::Symbolic::Constant->new($item[1])
            }

  function: function_name '(' expr_list ')'
            {
              #warn 'function ' 
              #  if $Math::Symbolic::Parser::DEBUG;
              my $fname = $item[1];
              my $function;
              if (exists($Math::Symbolic::Parser::Parser_Functions{$fname})) {
                $function = $Math::Symbolic::Parser::Parser_Functions{$fname}->($fname, @{$item[3]});
                die "Invalid function '$fname'!"
                  unless defined $function;
              }
              else {
                $function = $Math::Symbolic::Operator::Op_Symbols{ $fname };
                die "Invalid function '$fname'!"
                  unless defined $function;
                $function = Math::Symbolic::Operator->new(
                  { type => $function, operands => $item[3] }
                );
              }
              $function
            }

  function_name: 'log'
               | 'partial_derivative'
               | 'total_derivative'
               | 'sinh'
               | 'cosh'
               | 'asinh'
               | 'acosh'
               | 'asin'
               | 'acos'
               | 'atan2'
               | 'atan'
               | 'acot'
               | 'sin'
               | 'cos'
               | 'tan'
               | 'cot'
               | 'exp'
               | 'sqrt'


  expr_list: <leftop:expr ',' expr>
            {
              #warn 'expr_list '
              #  if $Math::Symbolic::Parser::DEBUG;
              $item[1]
            }

  variable: /[a-zA-Z][a-zA-Z0-9_]*/ /\'*/ '(' identifier_list ')'
            {
              #warn 'variable '
              #  if $Math::Symbolic::Parser::DEBUG;
              my $varname = $item[1];
              my $ticks = $item[2];
              if ($ticks) {
                my $n = length($ticks);
                my $sig = $item[4] || ['x'];
                my $dep_var = $sig->[0];
                my $return = Math::Symbolic::Variable->new(
                  { name => $varname, signature => $sig }
                );
                foreach (1..$n) {
                  $return = Math::Symbolic::Operator->new(
                    'partial_derivative', 
                     $return, $dep_var,
                  );
                }
                $return;
              }
              else {
                Math::Symbolic::Variable->new(
                  { name => $varname, signature => $item[4] }
                );
              }
            }

          | /[a-zA-Z][a-zA-Z0-9_]*/ /\'*/
            {
              #warn 'variable '
              #  if $Math::Symbolic::Parser::DEBUG;
              my $varname = $item[1];
              my $ticks = $item[2];
              if ($ticks) {
                my $n = length($ticks);
                my $return = Math::Symbolic::Variable->new(
                  { name => $varname, signature => ['x'] }
                );
                foreach (1..$n) {
                  $return = Math::Symbolic::Operator->new(
                    'partial_derivative', 
                     $return, 'x',
                  );
                }
                $return;
              }
              else {
                Math::Symbolic::Variable->new( $varname );
              }
            }

  identifier_list: <leftop:/[a-zA-Z][a-zA-Z0-9_]*/ ',' /[a-zA-Z][a-zA-Z0-9_]*/>
            {
              #warn 'identifier_list '
              #  if $Math::Symbolic::Parser::DEBUG;
              $item[1]
            }
  
GRAMMAR_END


=head2 Constructor new

This constructor does not expect any arguments and returns a Parse::RecDescent
parser to parse algebraic expressions from a string into Math::Symbolic
trees.

The constructor takes key/value pairs of options. 

You can regenerate the parser from the grammar in the scalar
C<$Math::Symbolic::Parser::Grammar> instead of using the (slightly faster)
precompiled grammar from L<Math::Symbolic::Parser::Precompiled>.
You can enable recompilation from the grammar with the option
C<recompile =E<gt> 1>. This only has an effect if the implementation
is the L<Parse::RecDescent> based parser (which is the default).

If you care about parsing speed more than about being able to extend the
parser at run-time, you can specify the C<implementation> option. Currently
recognized are C<RecDescent> and C<Yapp> implementations. C<RecDescent> is
the default and C<Yapp> is significantly faster. The L<Parse::Yapp> based
implementation may not support all extension modules. It has been tested
with Math::SymbolicX::ParserExtensionFactory and Math::SymbolicX::Complex.

=cut

sub new {
    my $class = shift;
    my %args = @_;

    my $impl = $args{implementation} || 'RecDescent';

    if ($impl eq 'RecDescent') {
        return $class->_new_recdescent(\%args);
    }
    elsif ($impl eq 'Yapp') {
        return $class->_new_yapp(\%args);
    }
    else {
        croak("'implementation' must be one of RecDescent or Yapp");
    }
}

sub _new_recdescent {
    my $class = shift;
    my $args = shift;

    if ( not $Required_Parse_RecDescent ) {
        local $@;
        eval 'require Parse::RecDescent;';
        croak "Could not require Parse::RecDescent. Please install\n"
          . "Parse::RecDescent in order to use Math::Symbolic::Parser.\n"
          . "(Error: $@)"
          if $@;
    }

    my $parser;

    if ( $args->{recompile} ) {
        $parser = Parse::RecDescent->new($Grammar);
        $parser->{__PRIV_EXT_FUNC_REGEX} = qr/(?!)/;
    }
    else {
        eval 'require Math::Symbolic::Parser::Precompiled;';
        if ($@) {
            $parser = Parse::RecDescent->new($Grammar);
            $parser->{__PRIV_EXT_FUNC_REGEX} = qr/(?!)/;
        }
        else {
            $parser = Math::Symbolic::Parser::Precompiled->new();
            $parser->{__PRIV_EXT_FUNC_REGEX} = qr/(?!)/;
        }
    }
    return $parser;
}

sub _new_yapp {
    my $class = shift;
    my $args = shift;
    eval 'require Math::Symbolic::Parser::Yapp';
    my %yapp_args;
    $yapp_args{predicates} = $args->{yapp_predicates}
      if $args->{yapp_predicates};
    if ($@) {
        croak("Could not load Math::Symbolic::Parser::Yapp. Error: $@");
    }
    else {
        return Math::Symbolic::Parser::Yapp->new(%yapp_args);
    }
}

1;
__END__

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>

L<Math::Symbolic::Parser::Precompiled>

=head1 ADDITIONAL COPYRIGHT NOTICE

This package is distributed under the same license as the rest of the
Math::Symbolic distribution (Artistic+GPL), but the author of Parse::Yapp
has requested that his copyright and the licensing terms of Parse::Yapp
derived works be reproduced. Note that the license is the same as
Math::Symbolic's license. We're using the "standalone parser" option.

  The Parse::Yapp module and its related modules and shell scripts
  are copyright (c) 1998-2001 Francois Desarmenien, France. All
  rights reserved.
  
  You may use and distribute them under the terms of either the GNU
  General Public License or the Artistic License, as specified in
  the Perl README file.
  
  If you use the "standalone parser" option so people don't need to
  install Parse::Yapp on their systems in order to run you software,
  this copyright notice should be included in your software
  copyright too, and the copyright notice in the embedded driver
  should be left untouched.

=cut

