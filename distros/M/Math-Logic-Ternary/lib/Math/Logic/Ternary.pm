# Copyright (c) 2006-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary;

use strict;
use warnings;
use Math::Logic::Ternary::Trit;
use Math::Logic::Ternary::Word;

require Exporter;

our $VERSION     = '0.004';
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    nil          true         false        ternary_trit
    word9        word27       word81       ternary_word
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub nil          { Math::Logic::Ternary::Trit->nil   }
sub true         { Math::Logic::Ternary::Trit->true  }
sub false        { Math::Logic::Ternary::Trit->false }
sub ternary_trit { Math::Logic::Ternary::Trit->from_various(@_) }

sub word9        { Math::Logic::Ternary::Word->from_various( 9, @_) }
sub word27       { Math::Logic::Ternary::Word->from_various(27, @_) }
sub word81       { Math::Logic::Ternary::Word->from_various(81, @_) }
sub ternary_word { Math::Logic::Ternary::Word->from_various(    @_) }

1;
__END__

=head1 NAME

Math::Logic::Ternary - ternary logic and related operations

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary.

=head1 SYNOPSIS

  use Math::Logic::Ternary qw(true false nil);
  use Math::Logic::Ternary qw(word9 word27 word81 ternary_word);
  use Math::Logic::Ternary qw(:all);

  $a = word9(        1234  );
  $a = word9(       '1234' );
  $a = word9(       '%bSS' );
  $a = word9(  '@tffntfnt' );

  $b = word9(       -5678  );
  $b = word9(      '-5678' );
  $b = word9(       '%SfS' );
  $b = word9( '@fnttfnfnt' );

  $c = $a->xor($b);             # word9(962)
  $d = $a->Cmp($b);             # true
  $e = $b->Sign;                # false

  # 1234 * -5678 + 962 == -7005690 == -356 * 3**9 + 1458
  ($f, $g) = $a->Mul($b, $c);   # (word9(1458), word9(-356))

=head1 DESCRIPTION

=head2 Introduction

Ternary or three-valued logic is a logic in which there are three truth
values indicating true, false and some third value, often used to denote
uncertainty or indefiniteness.

Ternary logic within a system of reasoning has come up in philosophy
as an alternative to classical logic.  Some spoken languages such
as Aymara allow to express ternary logical propositions more easily
than others.  Programming languages usually support just binary
logic.

Ternary logic and ternary number systems have applications in
engineering and computer science.  It is possible to build digital
systems based on ternary logic using memory units with three distinct
states (flip-flap-flops) and logic circuitry with three distinct
input/output levels, like positive, negative and zero voltage.  A
three-valued information unit is called a trit.

This library focuses on computational aspects of ternary logic.  It
provides a selection of operations a ternary computer might be
equipped with, and it addresses some related design considerations.

Objects accessible through Math::Logic::Ternary can represent single
trits or data words composed of several trits.  The module does not
overload Perl builtin operators, nor does it change semantics of
existing operators or control flow primitives.

Ternary truth values are called B<true>, B<false>, and B<nil> in
this module.

=head2 Embedding binary in ternary logic

Ternary logic can be seen as a generalization of binary ("Boolean")
logic, with operators working exactly like well-known Boolean
operators in the domain of I<true> and I<false> values while hopefully
still making some kind of sense in the presence of I<nil> values.

Different authors have used additional truth values for different
concepts and thus defined different ternary logic schemes.  We use
only one of these schemes here, namely Kleene ternary logic, for
its simplicity and symmetry.

In Kleene ternary logic, I<nil> can be thougt of as a value that can
either be true or false, but about which nothing is known at each time
of evaluation.  If I<nil> values take part in a logical expression, the
result can be calculated using Boolean logic by replacing all occurences
of I<nil> independently by I<true> and I<false> in turn (which requires
two to the power of the number of I<nil> values evaluations in total).
If the result is always the same, that value is also the value of the
ternary logical expression.  Otherwise, its value is I<nil>.

Note that in this approach, every occurence of I<nil> is treated
independently, even if some variables may be repeatedly involved.
This is a consequence of seeing I<nil> as a truth value of its own rather
than a placeholder for some unknown but fixed boolean value.

Examples:

  +-------+-------+
  |   A   | not A |
  +-------+-------+
  | false | true  |
  | nil   | nil   |
  | true  | false |
  +-------+-------+

  +-------+-------+---------+--------+---------+---------+
  |   A   |   B   | A and B | A or B | A eqv B | A xor B |
  +-------+-------+---------+--------+---------+---------+
  | false | false |  false  | false  |  true   |  false  |
  | false | nil   |  false  | nil    |  nil    |  nil    |
  | false | true  |  false  | true   |  false  |  true   |
  | nil   | false |  false  | nil    |  nil    |  nil    |
  | nil   | nil   |  nil    | nil    |  nil    |  nil    |
  | nil   | true  |  nil    | true   |  nil    |  nil    |
  | true  | false |  false  | true   |  false  |  true   |
  | true  | nil   |  nil    | true   |  nil    |  nil    |
  | true  | true  |  true   | true   |  true   |  false  |
  +-------+-------+---------+--------+---------+---------+

Note that the logical equivalence of two nil values is nil, not
true, just as the equivalence of two unknown conditions is unknown.
This also figures if "A is equivalent to B" is written as "(A and
B) or not (A or B)".  Trit equality, on the other hand, yields
always true or false, and of course true for two nil trits.  Symbolic
names for logical equivalence and trit equality relations are B<eqv>
and B<eq>, respectively.

=head2 Ternary number systems

Most suitable for arithmetic on a ternary computer are positional
number systems based on three digits.  This library provides arithmetic
of three different ternary number systems, namely balanced ternary,
unbalanced ternary and baseZ<>(-3).

Balanced ternary uses a base of 3 and the digits -1, 0 and 1.
Unbalanced ternary uses a base of 3 and the digits 0, 1 and 2.
BaseZ<>(-3) uses a base of -3 and the digits 0, 1, and 2.

Unfortunately, there seems to be no general agreement on which
ternary truth value should be associated with a given numerical
value.  The choices in this module are as follows:

=over 4

=item *

Negative values (in balanced ternary representation) are considered false.

=item *

Positive values (in balanced ternary representation) are considered true.

=item *

Zero is associated with the remaining truth value, neither true nor false.

=back

These choices are motivated mostly by symmetry considerations.

Consequently, logical values of false, nil, true correspond to
balanced single trit values of C<-1>, C<0>, C<+1> respectively.
Some examples:

  +--------+-----------------+-------------+------------+
  | number | balanced trits  | truth value | sign value |
  +--------+-----------------+-------------+------------+
  |   -4   | (-1) * 3 + (-1) |   false     |     -1     |
  |   -3   | (-1) * 3 +   0  |   false     |     -1     |
  |   -2   | (-1) * 3 + (+1) |   false     |     -1     |
  |   -1   |   0  * 3 + (-1) |   false     |     -1     |
  |    0   |   0  * 3 +   0  |   nil       |      0     |
  |    1   |   0  * 3 + (+1) |   true      |     +1     |
  |    2   | (+1) * 3 + (-1) |   true      |     +1     |
  |    3   | (+1) * 3 +   0  |   true      |     +1     |
  |    4   | (+1) * 3 + (+1) |   true      |     +1     |
  +--------+-----------------+-------------+------------+

For unbalanced arithmetic, trit value -1 is replaced by 2 and the
other values are left alone.  This means that addition modulo 3 is
the same operation in balanced and unbalanced base 3 arithmetic,
whereas comparison operations are quite different.

  +--------+------------------+
  | number | unbalanced trits |
  +--------+------------------+
  |    0   |   0 * 3  +  0    |
  |    1   |   0 * 3  +  1    |
  |    2   |   0 * 3  +  2    |
  |    3   |   1 * 3  +  0    |
  |    4   |   1 * 3  +  1    |
  |    5   |   1 * 3  +  2    |
  |    6   |   2 * 3  +  0    |
  |    7   |   2 * 3  +  1    |
  |    8   |   2 * 3  +  2    |
  +--------+------------------+

Note that this particular implementation of unbalanced ternary
arithmetic does not deal with negative numbers, avoiding another
controversial choice among different possible representations.

Possible solutions include treating the most significant trit as
balanced ternary digit, or using an extra trit to hold just the sign,
or implicitly shifting the unsigned number range down by exactly half
of its maximum.  All of these result in complications that are absent
in balanced arithmetic, so they should not be missed very much.

The negative base case, finally, shares the trit values of the
unbalanced case but assigns different weights.  The sign of a
negative base number is determined by the position of the most
significant nonzero trit.

  +--------+------------------+------------+
  |        |                  |  base(-3)  |
  | number | unbalanced trits | sign value |
  +--------+------------------+------------+
  |   -6   |  2 * (-3) +  0   |     -1     |
  |   -5   |  2 * (-3) +  1   |     -1     |
  |   -4   |  2 * (-3) +  2   |     -1     |
  |   -3   |  1 * (-3) +  0   |     -1     |
  |   -2   |  1 * (-3) +  1   |     -1     |
  |   -1   |  1 * (-3) +  2   |     -1     |
  |    0   |  0 * (-3) +  0   |      0     |
  |    1   |  0 * (-3) +  1   |     +1     |
  |    2   |  0 * (-3) +  2   |     +1     |
  +--------+------------------+------------+

=head2 Objects

The core of this library revolves around two basic object classes,
Math::Logic::Ternary::Trit and Math::Logic::Ternary::Word.  A trit
is the smallest ternary information unit.  It has a range of three
values.  A word is a container for many trits.  Words come in
different sizes: typical are 9, 27, or 81 trits.  Words of all sizes
are implemented in the Word class.

The top level module Math::Logic::Ternary wraps up constructors
for both object classes in a single interface.  It also contains
the introductory documentation you are reading right now.

Trit and Word objects generally represent constants and have therefore
no alterable attributes.  Computations yielding new values will
create new objects.

Trit and Word object classes share a couple of methods through their
common Math::Logic::Ternary::Object role.  This makes it possible to use
trits and words interchangeably in many places, most notably as second,
third or fourth operands.  Note however that leftmost operands acting
as method invocants of course do have to be in the class defining the
desired operator as method.  (We might have taken this further, even
thrown both classes together, but felt keeping the distinction to be
the more natural choice.)

=head2 Comparison of word sizes

  +-------------+-------------+--------------+
  | ternary     | binary      | decimal      |
  +-------------+-------------+--------------+
  |     9 trits |  14.26 bits |  4.29 digits |
  |    27 trits |  42.79 bits | 12.88 digits |
  |    81 trits | 128.38 bits | 38.65 digits |
  +-------------+-------------+--------------+
  | 10.09 trits |     16 bits |  4.82 digits |
  | 20.19 trits |     32 bits |  9.63 digits |
  | 40.38 trits |     64 bits | 19.27 digits |
  | 80.76 trits |    128 bits | 38.53 digits |
  +-------------+-------------+--------------+
  | 12.58 trits |  19.93 bits |     6 digits |
  | 18.86 trits |  29.90 bits |     9 digits |
  | 25.15 trits |  39.86 bits |    12 digits |
  | 37.73 trits |  59.79 bits |    18 digits |
  | 50.30 trits |  79.73 bits |    24 digits |
  | 75.45 trits | 119.59 bits |    36 digits |
  +-------------+-------------+--------------+

  +-------+----------------------------------------------------+
  | trits |                   balanced range                   |
  +-------+----------------------------------------------------+
  |   9   |                   -9841 ..  9841                   |
  +-------+----------------------------------------------------+
  |  27   |        -3_812798_742493 .. 3_812798_742493         |
  +-------+----------------------------------------------------+
  |  81   | -221_713244_121518_884974_124815_309574_946401 ..  |
  |       |  221_713244_121518_884974_124815_309574_946401     |
  +-------+----------------------------------------------------+

  +-------+----------------------------------------------------+
  | trits |                  unbalanced range                  |
  +-------+----------------------------------------------------+
  |   9   |                       0 .. 19682                   |
  +-------+----------------------------------------------------+
  |  27   |                       0 .. 7_625597_484986         |
  +-------+----------------------------------------------------+
  |  81   |                                              0 ..  |
  |       |  443_426488_243037_769948_249630_619149_892802     |
  +-------+----------------------------------------------------+

  +-------+----------------------------------------------------+
  | trits |                   base(-3) range                   |
  +-------+----------------------------------------------------+
  |   9   |                   -4920 .. 14762                   |
  +-------+----------------------------------------------------+
  |  27   |        -1_906399_371246 .. 5_719198_113740         |
  +-------+----------------------------------------------------+
  |  81   | -110_856622_060759_442487_062407_654787_473200 ..  |
  |       |  332_569866_182278_327461_187222_964362_419602     |
  +-------+----------------------------------------------------+

=head2 String Representations of Ternary Data

This library supports several formats for input and output of ternary
data.  Special prefix characters help to disambiguate among these.
Single trits can be represented by their names as C<'$true'>, C<'$false'>,
or C<'$nil'>, respectively.

All objects have numeric values in all three implemented number systems.
These numeric values can be represented as decimal integer numbers.

Ternary words can also be represented as sequences of C<'t'>, C<'f'>,
or C<'n'> characters with a C<'@'> prefix.  Like decimal numbers,
these are written left to right from most to least significant unit.
Note that trits within word objects and words within arrays of word
objects are addressed with the least significant element at index zero,
though.

Finally, a more compact format for ternary words uses 27 symbols,
namely 26 ASCII letters and the underscore.  This format is called
base27 here and uses a prefix of C<'%'>.  In base27, the underscore
represents a value of zero, lower case letters C<'a'> through C<'m'>
represent values of one through 13, and upper case letters C<'N'> through
C<'Z'> represent values of -13 through -1.  In input, case is ignored.
In output, case is chosen such that lexical sorting in the C<'C'> locale
will preserve order.  Again, most significant units are written leftmost.

Examples for all word to string conversions can be found in
L<Math::Logic::Ternary::Word>.

=head2 Exports

None by default.

These functions can be explicitly imported:

I<nil>, I<true>, I<false>, I<ternary_trit>,
I<word9>, I<word27>, I<word81>, and I<ternary_word>.

The export tag I<:all> is a symbol for all of them.

=head2 Convenience Functions

=head3 nil

The I<nil> trit.

=head3 true

The I<true> trit.

=head3 false

The I<false> trit.

=head3 ternary_trit($arg)

The trit identified by I<$arg>.

The argument can be a small integer, 0 for nil, 1 for true, -1 or 2 for false.
It can also be one of the strings '$true', '$false', or '$nil'.

=head3 word9(@args)

Equivalent to ternary_word(9, @args).

=head3 word27(@args)

Equivalent to ternary_word(27, @args).

=head3 word81(@args)

Equivalent to ternary_word(81, @args).

=head3 ternary_word($n, $int)

Ternary word with I<$n> trits, given as an integer.

=head3 ternary_word($n, $str)

Ternary word with I<$n> trits, given as a string of 't'/'n'/'f' characters
with prefix '@', or a string of base27 characters with prefix '%'.

=head3 ternary_word($n, @trits)

Ternary word with I<$n> trits, given as a list of trit values, read
from lowest to highest significance, to be padded with nil trits.

=head1 ROADMAP

=over 4

=item *

Binary/ternary conversions.

=item *

Fully implement floating point arithmetic.

=item *

Efficient multiplication and division.

=item *

Tcalc file I/O and batch mode.

=item *

Math::Logic::Ternary::Hardware - modelling ternary digital circuitry

=back

=head1 DEPENDENCIES

This version of Math-Logic-Ternary requires these other modules and
libraries to run:

=over 4

=item *

perl version 5.8.0 or higher

=item *

L<Math::BigInt> version 1.78 or higher (usually bundled with perl)

=item *

L<Role::Basic> (available on CPAN)

=back

Additional requirements to run the test suite are:

=over 4

=item *

L<Test::More> (usually bundled with perl)

=back

Recommended modules for increased functionality are:

=over 4

=item *

L<Math::ModInt> (available on CPAN)

=item *

L<Term::ReadLine> (available on CPAN)

=back

=head1 BUGS AND LIMITATIONS

As of version 0.004, the list of numerical operators and corresponding
low-level trit operators is not at all complete.

For example, operators to divide a value by two and compute the arithmetic
mean of two values are already in the pipeline but did not make it into
the release.

This library in general is a work in progress and in the
state of beta testing.  Feel free to
send comments, observations and suggestions to the author.  He would
especially like to hear about features actually implemented in ternary
digital hardware, whether addressed in this library or not.

Version 0.004 is the first official beta release of the library.
Earlier versions should no longer be used.  Upcoming development
will aim to extend the API without radically changing existent
functionality, unless of course there is a compelling reason to do
so.  At the present stage, nothing should be considered final.

Please submit bug reports and suggestions through the CPAN RT,
L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Math-Logic-Ternary> .

=head1 PROVIDED MODULES AND SCRIPTS

The distribution provides 16 modules and one pod-only file in the
Math::Logic::Ternary namespace.

Additionally, an interactive ternary calculator is provided as executable
script C<tcalc>.

=head1 RESOURCES

=over 4

=item Project Homepage

L<https://vera.in-ulm.de/ternary-logic/>

=item Bug Tracker

L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Math-Logic-Ternary>

=back

=head1 SEE ALSO

=over 4

=item *

L<Math::Logic::Ternary::Trit> - Ternary Logical Information Unit

=item *

L<Math::Logic::Ternary::Word> - Fixed-Size Ternary Information Compound

=item *

L<Math::Logic::Ternary::Expression> - Ternary Logic on Native Perl Expressions

=item *

L<Math::Logic::Ternary::Calculator> - Interactive Ternary Calculator

=item *

L<Math::Logic::Ternary::Calculator::Manual> - User Manual for tcalc

=item *

L<Math::Logic::Ternary::TFP_81> - 81-Trit Ternary Floating Point Arithmetic

=item *

L<Math::Logic::Ternary::TAPI27> - Ternary Arbitrary Precision Integer Format

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2017 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
