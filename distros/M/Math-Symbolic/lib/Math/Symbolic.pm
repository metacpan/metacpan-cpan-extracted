=encoding utf8

=head1 NAME

Math::Symbolic - Symbolic calculations

=head1 SYNOPSIS

  use Math::Symbolic;
  
  my $tree = Math::Symbolic->parse_from_string('1/2 * m * v^2');
  # Now do symbolic calculations with $tree.
  # ... like deriving it...
  
  my ($sub) = Math::Symbolic::Compiler->compile_to_sub($tree);

  my $kinetic_energy = $sub->($mass, $velocity);

=head1 DESCRIPTION

Math::Symbolic is intended to offer symbolic calculation capabilities
to the Perl programmer without using external (and commercial) libraries
and/or applications.

Unless, however, some interested and knowledgable developers turn up to
participate in the development, the library will be severely limited by
my experience in the area. Symbolic calculations are an active field of
research in CS.

There are several ways to construct Math::Symbolic trees. There are no
actual Math::Symbolic objects, but rather trees of objects of subclasses of
Math::Symbolic. The most general but unfortunately also the least intuitive
way of constructing trees is to use the constructors of
the Math::Symbolic::Operator, Math::Symbolic::Variable, and
Math::Symbolic::Constant classes to create (nested) objects of the
corresponding types.

Furthermore, you may use the overloaded interface to apply the standard
Perl operators (and functions, see L<OVERLOADED OPERATORS>) to existing
Math::Symbolic trees and standard Perl expressions.

Possibly the most convenient way of constructing Math::Symbolic trees is
using the builtin parser to generate trees from expressions such as C<2 * x^5>.
You may use the C<Math::Symbolic-E<gt>parse_from_string()> class method for this.

Of course, you may combine the overloaded interface with the parser to
generate trees with Perl code such as C<$term * 5 * 'sin(omega*t+phi)'> which
will create a tree of the existing tree $term times 5 times the sine of
the vars omega times t plus phi.

There are several modules in the distribution that contain subroutines
related to calculus. These are not loaded by Math::Symbolic by default.
Furthermore, there are several extensions to Math::Symbolic available
from CPAN as separate distributions. Please refer to L<SEE ALSO>
for an incomplete list of these.

For example, L<Math::Symbolic::MiscCalculus> come with C<Math::Symbolic> and
contains routines to compute Taylor Polynomials and the associated errors.

Routines related to vector calculus such as grad, div, rot, and Jacobi- and
Hesse matrices are available through the L<Math::Symbolic::VectorCalculus>
module. This module is also able to compute Taylor Polynomials of
functions of two variables, directional derivatives, total differentials,
and Wronskian Determinants.

Some basic support for linear algebra can be found in
L<Math::Symbolic::MiscAlgebra>. This includes a routine to compute
the determinant of a matrix of C<Math::Symbolic> trees.

=head2 EXPORT

None by default, but you may choose to have the following constants
exported to your namespace using the standard Exporter semantics.
There are two export tags: :all and :constants. :all will export
all constants and the parse_from_string subroutine.

  Constants for transcendetal numbers:
    EULER (2.7182...)
    PI    (3.14159...)
    
  Constants representing operator types: (First letter indicates arity)
  (These evaluate to the same numbers that are returned by the type()
   method of Math::Symbolic::Operator objects.)
    B_SUM
    B_DIFFERENCE
    B_PRODUCT
    B_DIVISION
    B_LOG
    B_EXP
    U_MINUS
    U_P_DERIVATIVE (partial derivative)
    U_T_DERIVATIVE (total derivative)
    U_SINE
    U_COSINE
    U_TANGENT
    U_COTANGENT
    U_ARCSINE
    U_ARCCOSINE
    U_ARCTANGENT
    U_ARCCOTANGENT
    U_SINE_H
    U_COSINE_H
    U_AREASINE_H
    U_AREACOSINE_H
    B_ARCTANGENT_TWO
    
  Constants representing Math::Symbolic term types:
  (These evaluate to the same numbers that are returned by the term_type()
   methods.)
    T_OPERATOR
    T_CONSTANT
    T_VARIABLE
  
  Subroutines:
    parse_from_string (returns Math::Symbolic tree)

=cut

package Math::Symbolic;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Symbolic::ExportConstants qw/:all/;
use Math::Symbolic::AuxFunctions;

use Math::Symbolic::Base;
use Math::Symbolic::Operator;
use Math::Symbolic::Variable;
use Math::Symbolic::Constant;

use Math::Symbolic::Derivative;

use Math::Symbolic::Parser;
use Math::Symbolic::Compiler;

use Math::Symbolic::Custom;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    all => [
        @{ $Math::Symbolic::ExportConstants::EXPORT_TAGS{all} },
        qw{&parse_from_string},
    ],
    constants => [ @{ $Math::Symbolic::ExportConstants::EXPORT_TAGS{all} }, ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = qw();

our $VERSION = '0.612';

=head1 CLASS DATA

The package variable $Parser will contain a Parse::RecDescent
object that is used to parse strings at runtime.

=cut

our $Parser = Math::Symbolic::Parser->new();

=head1 SUBROUTINES

=head2 parse_from_string

This subroutine takes a string as argument and parses it using
a Parse::RecDescent parser taken from the package variable
$Math::Symbolic::Parser. It generates a Math::Symbolic tree
from the string and returns that tree.

The string may contain any identifiers matching /[a-zA-Z][a-zA-Z0-9_]*/ which
will be parsed as variables of the corresponding name.

Please refer to L<Math::Symbolic::Parser> for more information.

=cut

sub parse_from_string {
    my $string = shift;
    croak "Missing string argument from parse_from_string() call"
      unless defined $string;
    if ($string eq 'Math::Symbolic') {
        if (@_) {
            $string = shift;
        }
        else {
          croak("Missing string argument from Math::Symbolic->parse_from_string() call");
        }
    }
    $string =~ s/\s+//gso;
    if ( not defined $Parser ) {
        $Parser = Math::Symbolic::Parser->new();
    }
    return $Parser->parse($string);
}

1;
__END__

=head1 EXAMPLES

This example demonstrates variable and operator creation using
object prototypes as well as partial derivatives and the various
ways of applying derivatives and simplifying terms. Furthermore, it
shows how to use the compiler for simple expressions.

  use Math::Symbolic qw/:all/;
  
  my $energy = parse_from_string(<<'HERE');
        kinetic(mass, velocity, time) +
        potential(mass, z, time)
  HERE
  
  $energy->implement(kinetic => '(1/2) * mass * velocity(time)^2');
  $energy->implement(potential => 'mass * g * z(t)');
  
  $energy->set_value(g => 9.81); # permanently
  
  print "Energy is: $energy\n";
  
  # Is how does the energy change with the height?
  my $derived = $energy->new('partial_derivative', $energy, 'z');
  $derived = $derived->apply_derivatives()->simplify();
  
  print "Changes with the heigth as: $derived\n";
  
  # With whatever values you fancy:
  print "Putting in some sample values: ",
        $energy->value(mass => 20, velocity => 10, z => 5),
        "\n";
  
  # Too slow?
  $energy->implement(g => '9.81'); # To get rid of the variable
  
  my ($sub) = Math::Symbolic::Compiler->compile($energy);
  
  print "This was much faster: ",
        $sub->(20, 10, 5),  # vars ordered alphabetically
        "\n";

=head1 OVERLOADED OPERATORS

Since version 0.102, several arithmetic operators have been overloaded.

That means you can do most arithmetic with Math::Symbolic trees just as
if they were plain Perl scalars.

The following operators are currently overloaded to produce valid
Math::Symbolic trees when applied to an expression involving at least one
Math::Symbolic object:

  +, -, *, /, **, sqrt, log, exp, sin, cos

Furthermore, some contexts have been overloaded with particular behaviour:
'""' (stringification context) has been overloaded to produce the string
representation of the object. '0+' (numerical context) has been overloaded
to produce the value of the object. 'bool' (boolean context) has been
overloaded to produce the value of the object.

If one of the operands of an overloaded operator is a Math::Symbolic tree and
the over is undef, the module will throw an error I<unless the operator
is a + or a ->. If the operator is an addition, the result will be the
original Math::Symbolic tree. If the operator is a subtraction, the result will
be the negative of the Math::Symbolic tree. Reason for this inconsistent
behaviour is that it makes idioms like the following possible:

  @objects = (... list of Math::Symbolic trees ...);
  $sum += $_ foreach @objects;

Without this behaviour, you would have to shift the first object into $sum
before using it. This is not a problem in this case, but if you are applying
some complex calculation to each object in the loop body before adding it to
the sum, you'd have to either split the code into two loops or replicate the
code required for the complex calculation when shift()ing the first object
into $sum.

B<Warning:> The operator to use for exponentiation is the normal Perl
operator for exponentiation C<**>, NOT the caret C<^> which denotes
exponentiation in the notation that is recognized by the Math::Symbolic
parsers! The C<^> operator will be interpreted as the normal binary xor.

=head1 EXTENDING THE MODULE

Due to several design decisions, it is probably rather difficult to extend
the Math::Symbolic related modules through subclassing. Instead, we
chose to make the module extendable through delegation.

That means you can introduce your own methods to extend Math::Symbolic's
functionality. How this works in detail can be read in
L<Math::Symbolic::Custom>.

Some of the extensions available via CPAN right now are listed in the
L<SEE ALSO> section.

=head1 PERFORMANCE

Math::Symbolic can become quite slow if you use it wrong. To be honest, it can
even be slow if you use it correctly. This section is meant to give you an
idea about what you can do to have Math::Symbolic compute as quickly as
possible. It has some explanation and a couple of 'red flags' to watch out for.
We'll focus on two central points: Creation and evaluation.

=head2 CREATING Math::Symbolic TREES

Math::Symbolic provides several means of generating Math::Symbolic trees
(which are just trees of Math::Symbolic::Constant, Math::Symbolic::Variable
and most importantly Math::Symbolic::Operator objects).

The most convenient way is to use the builtin parser (for example via the 
C<parse_from_string()> subroutine). Problem is, this darn thing becomes
really slow for long input strings. This is a known problem for 
Parse::RecDescent parsers and the Math::Symbolic grammar isn't the shortest
either.

B<Try to break the formulas you parse into smallish bits. Test the parser
performance to see how small they need to be.>

I'll give a simple example where this first advice is gospel:

  use Math::Symbolic qw/parse_from_string/;
  my @formulas;
  foreach my $var (qw/x y z foo bar baz/) {
      my $formula = parse_from_string("sin(x)*$var+3*y^z-$var*x");
      push @formulas, $formula;
  }

So what's wrong here? I'm parsing the whole formula every time. How about this?

  use Math::Symbolic qw/parse_from_string/;
  my @formulas;
  my $sin = parse_from_string('sin(x)');
  my $term = parse_from_string('3*y^z');
  my $x = Math::Symbolic::Variable->new('x');
  foreach my $var (qw/x y z foo bar baz/) {
	  my $v = $x->new($var);
      my $formula = $sin*$var + $term - $var*$x;
      push @formulas, $formula;
  }

I wouldn't call that more legible, but you notice how I moved all the
heavy lifting out of the loop. You'll know and do this for normal code, but it's
maybe not as obvious when dealing with such code. Now, since this is still
slow and - if anything - ugly, we'll do something really clever now to get the
best of both worlds!

  use Math::Symbolic qw/parse_from_string/;
  my @formulas;
  my $proto = parse_from_string('sin(x)*var+3*y^z-var*x");
  foreach my $var (qw/x y z foo bar baz/) {
      my $formula = $proto->new();
      $formula->implement(var => Math::Symbolic::Variable->new($var));
      push @formulas, $formula;
  }

Notice how we can combine legibility of a clean formula with removing all
parsing work from the loop? The C<implement()> method is described in
detail in L<Math::Symbolic::Base>.

On a side note: One thing you could do to bring your computer to its knees
is to take a
function like I<sin(a*x)*cos(b*x)/e^(2*x)>, derive that in respect to I<x> a
couple of times (like, erm, 50 times?), call C<to_string()> on it and
parse that string again.

Almost as convenient as the parser is the overloaded interface.
That means, you create a Math::Symbolic object and use it in 
algebraic expressions
as if it was a variable or number. This way, you can even multiply a
Math::Symbolic tree with a string and have the string be parsed as a subtree.
Example:

  my $x = Math::Symbolic::Variable->new('x');
  my $formula = $x - sin(3*$x); # $formula will be a M::S tree
  # or:
  my $another = $x - 'sin(3*x)'; # have the string parsed as M::S tree

This, however, turns out to be rather slow, too. It is only about two to five
times faster than parsing the formula all the way.

B<Use the overloaded interface to construct trees from existing Math::Symbolic
objects, but if you need to create new trees quickly, resort to building
them by hand.>

Finally, you can create objects using the C<new()> constructors from
Math::Symbolic::Operator and friends. These can be called in two forms,
a long one that gives you complete control (signature for variables, etc.)
and a short hand. Even if it is just to protect your finger tips from burning,
you should use the short hand whenever possible. It is also I<slightly> faster.

B<Use the constructors to build Math::Symbolic trees if you need speed.
Using a prototype object and calling C<new()> on that may help with the
typing effort and should not result in a slow down>.

=head2 CRUNCHING NUMBERS WITH Math::Symbolic

As with the generation of Math::Symbolic trees, the evaluation of a formula
can be done in distinct ways.

The simplest is, of course, to call C<value()> on the tree and have
that calculate the value of the formula. You might have to supply some
input values to the formula via C<value()>, but you can also call
C<set_value()> before using C<value()>. But that's not faster.
For each call to C<value()>, the computer walks the complete Math::Symbolic
tree and evaluates the nodes. If it reaches a leaf, the resulting value is
propagated back up the tree. (It's a depth-first search.)

B<Calling value() on a Math::Symbolic tree requires walking the tree for
every evaluation of the formula. Use this if you'll evaluate the formula
only a few times.>

You may be able to make the formula simpler using the Math::Symbolic 
simplification routines (like C<simplify()> or some stuff in the 
Math::Symbolic::Custom::* modules). Simpler formula are quicker to evaluate.
In particular, the simplification should fold constants.

B<If you're going to evaluate a tree many times, try simplifying it first.>

But again, your mileage may vary. Test first.

If the overhead of calling C<value()> is unaccepable, you should use the
Math::Symbolic::Compiler to compile the tree to Perl code. (Which usually
comes in compiled form as an anonymous subroutine.) Example:

  my $tree = parse_from_string('3*x+sin(y)^(z+1)');
  my $sub = $tree->to_sub(y => 0, x => 1, z => 2);
  foreach (1..100) {
    # define $x, $y, and $z
    my $res = $sub->($y, $x, $z);
    # faster than $tree->value(x => $x, y => $y, z => $z) !!!
  }

B<Compile your Math::Symbolic trees to Perl subroutines for evaluation in
tight loops. The speedup is in the range of a few thousands.>

On an interesting side note, the subroutines compiled from Math::Symbolic
trees are just as fast as hand-crafted, "performance tuned" subroutines.

If you have extremely long formulas, you can choose to even resort to more
extreme measures than generating Perl code. You can have Math::Symbolic
generate C code for you, compile that and link it into your application at run
time. It will then be available to you as a subroutine.

This is not the most portable thing to do. (You need Inline::C which
in turn needs the C compiler that was used to compile your perl.)
Therefore, you need to install an extra module for this. It's called
L<Math::Symbolic::Custom::CCompiler>. The speed-up for short formulas
is only about factor 2 due to the overhead of calling the Perl subroutine, but
with sufficiently complicated formulas, you should be able to get a boost
up to factor 100 or even 1000.

B<For raw execution speed, compile your trees to C code using 
Math::Symbolic::Custom::CCompiler.>

=head2 PROOF

In the last two sections, you were told a lot about the performance of
two important aspects of Math::Symbolic handling. But eventhough benchmarks
are very system dependent and have limited meaning to the general case,
I'll supply some proof for what I claimed. This is
Perl 5.8.6 on linux-2.6.9, x86_64 (Athlon64 3200+).

In the following tables, I<value> means evaluation using the C<value()> method,
I<eval> means evaluation of Perl code as a string, I<sub> is a hand-crafted
Perl subroutine, I<compiled> is the compiled Perl code, I<c> is the compiled
C code. Evaluation of a very simple function yields:

  f(x) = x*2
                Rate    value     eval      sub compiled        c
  value      17322/s       --     -68%     -99%     -99%     -99%
  eval       54652/s     215%       --     -97%     -97%     -97%
  sub      1603578/s    9157%    2834%       --      -1%     -16%
  compiled 1616630/s    9233%    2858%       1%       --     -15%
  c        1907541/s   10912%    3390%      19%      18%       --

We see that resorting to C is a waste in such simple cases. Compiling to
a Perl sub, however is a good idea.

  f(x,y,z) = x*y*z+sin(x*y*z)-cos(x*y*z)
                Rate    value     eval compiled      sub        c
  value       1993/s       --     -88%    -100%    -100%    -100%
  eval       16006/s     703%       --     -97%     -97%     -99%
  compiled  544217/s   27202%    3300%       --      -2%     -56%
  sub       556737/s   27830%    3378%       2%       --     -55%
  c        1232362/s   61724%    7599%     126%     121%       --
  
  f(x,y,z,a,b) = x^y^tan(a*z)^(y*sin(x^(z*b)))
               Rate    value     eval compiled      sub        c
  value      2181/s       --     -84%     -99%     -99%    -100%
  eval      13613/s     524%       --     -97%     -97%     -98%
  compiled 394945/s   18012%    2801%       --      -5%     -48%
  sub      414328/s   18901%    2944%       5%       --     -46%
  c        763985/s   34936%    5512%      93%      84%       --

These more involved examples show that using I<value()> can become unpractical
even if you're just doing a 2D plot with just a few thousand points.
The C routines aren't I<that> much faster, but they scale much better.

Now for something different. Let's see whether I lied about the creation of
Math::Symbolic trees. I<parse> indicates that the parser was used to create
the object tree. I<long> indicates that the long syntax of the constructor
was used. I<short>... well. I<proto> means that the objects were created from
prototypes of the same class. For I<ol_long> and I<ol_parse>, I used the
overloaded interface in conjunction with constructors or parsing (a la
C<$x * 'y+z'>).

  f(x) = x
               Rate  parse  long   short  ol_long  ol_parse  proto
  parse       258/s     --  -100%  -100%    -100%     -100%  -100%
  long      95813/s 37102%     --   -33%     -34%      -34%   -35%
  short    143359/s 55563%    50%     --      -2%       -2%    -3%
  ol_long  146022/s 56596%    52%     2%       --       -0%    -1%
  ol_parse 146256/s 56687%    53%     2%       0%        --    -1%
  proto    147119/s 57023%    54%     3%       1%        1%     --

Obviously, the parser gets blown to pieces, performance-wise. If you want to
use it, but cannot accept its tranquility, you can resort to
Math::SymbolicX::Inline and have the formulas parsed at compile time. (Which
isn't faster, but means that they are available when the program runs.)
All other methods are about the same speed. Note, that the ol_* tests
are just the same as I<short> here, because in case of C<f(x) = x>, you cannot
make use of the overloaded interface.

  f(x,y,a,b) = x*y(a,b)
              Rate  parse  ol_parse ol_long   long  proto  short
  parse      125/s     --      -41%    -41%  -100%  -100%  -100%
  ol_parse   213/s    70%        --     -0%   -99%   -99%   -99%
  ol_long    213/s    70%        0%      --   -99%   -99%   -99%
  long     26180/s 20769%    12178%  12171%     --    -6%   -10%
  proto    27836/s 22089%    12955%  12947%     6%     --    -5%
  short    29148/s 23135%    13570%  13562%    11%     5%     --

  f(x,a) = sin(x+a)*3-5*x
              Rate    parse ol_long ol_parse     proto     short
  parse     41.2/s       --    -83%     -84%     -100%     -100%
  ol_long    250/s     505%      --      -0%      -97%      -98%
  ol_parse   250/s     506%      0%       --      -97%      -98%
  proto     9779/s   23611%   3819%    3810%        --       -3%
  short    10060/s   24291%   3932%    3922%        3%        --

The picture changes when we're dealing with slightly longer functions.
The performance of the overloaded interface isn't that much better than the
parser. (Since it uses the parser to convert non-Math::Symbolic operands.)
I<ol_long> should, however, be faster than I<ol_parse>. I'll refine the
benchmark somewhen. The three other construction methods are still about
the same speed. I omitted the long version in the last benchmark because
the typing work involved was unnerving.

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

The following modules come with this distribution:

L<Math::Symbolic::ExportConstants>,
L<Math::Symbolic::AuxFunctions>

L<Math::Symbolic::Base>,
L<Math::Symbolic::Operator>,
L<Math::Symbolic::Constant>,
L<Math::Symbolic::Variable>

L<Math::Symbolic::Custom>,
L<Math::Symbolic::Custom::Base>,
L<Math::Symbolic::Custom::DefaultTests>,
L<Math::Symbolic::Custom::DefaultMods>
L<Math::Symbolic::Custom::DefaultDumpers>

L<Math::Symbolic::Derivative>,
L<Math::Symbolic::MiscCalculus>,
L<Math::Symbolic::VectorCalculus>,
L<Math::Symbolic::MiscAlgebra>

L<Math::Symbolic::Parser>,
L<Math::Symbolic::Parser::Precompiled>,
L<Math::Symbolic::Compiler>

The following modules are extensions on CPAN that do not come with this
distribution in order to keep the distribution size reasonable.

L<Math::SymbolicX::Inline> - (Inlined Math::Symbolic functions)

L<Math::Symbolic::Custom::CCompiler> (Compile Math::Symbolic trees to C
for speed or for use in C code)

L<Math::SymbolicX::BigNum> (Big number support for the Math::Symbolic parser)

L<Math::SymbolicX::Complex> (Complex number support for the Math::Symbolic
parser)

L<Math::Symbolic::Custom::Contains> (Find subtrees in Math::Symbolic
expressions)

L<Math::SymbolicX::ParserExtensionFactory> (Generate parser extensions for the
Math::Symbolic parser)

L<Math::Symbolic::Custom::ErrorPropagation> (Calculate Gaussian Error
Propagation)

L<Math::SymbolicX::Statistics::Distributions> (Statistical Distributions as
Math::Symbolic functions)

L<Math::SymbolicX::NoSimplification> (Turns off Math::Symbolic simplifications)

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, smueller at cpan dot org
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011,
2013 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
