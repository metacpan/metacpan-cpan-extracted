#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package List::Keywords 0.03;

use v5.14;
use warnings;

use Carp;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<List::Keywords> - a selection of list utility keywords

=head1 SYNOPSIS

   use List::Keywords 'any';

   my @boxes = ...;

   if( any { $_->size > 100 } @boxes ) {
      say "There are some large boxes here";
   }

=head1 DESCRIPTION

This module provides keywords that behave (almost) identically to familiar
functions from L<List::Util>, but implemented as keyword plugins instead of
functions. As a result these run more efficiently, especially in small code
cases.

=head2 Blocks vs Anonymous Subs

In the description above the word "almost" refers to the fact that as this
module provides true keywords, the code blocks to them can be parsed as true
blocks rather than anonymous functions. As a result, both C<caller> and
C<return> will behave rather differently here.

For example,

   use List::Keywords 'any';

   sub func {
      any { say "My caller is ", caller; return "ret" } 1, 2, 3;
      say "This is never printed";
   }

Here, the C<caller> will see C<func> as its caller, and the C<return>
statement makes the entire containing function return, so the second line is
never printed. The same example written using C<List::Util> will instead print
the C<List::Util::any> function as being the caller, before making just that
one item return the value, then the message on the second line is printed as
normal.

In regular operation where the code is just performing some test on each item,
and does not make use of C<caller> or C<return>, this should not cause any
noticable differences.

=head2 Performance

The following example demonstrates a simple case and shows how the performance
differs.

   my @nums = (1 .. 100);

   my $ret = any { $_ > 50 } @nums;

When run for 5 seconds each, the following results were obtained on my
machine:

   List::Util::any      648083/s
   List::Keyword/any    816135/s

The C<List::Keyword> version here ran 26% faster.

=cut

my %KEYWORD_OK = map { $_ => 1 } qw(
   first any all none notall
);

sub import
{
   shift;
   my @syms = @_;

   foreach ( @syms ) {
      $KEYWORD_OK{$_} or croak "Unrecognised import symbol '$_'";

      $^H{"List::Keywords/$_"}++;
   }
}

=head1 KEYWORDS

=cut

=head2 first

   $val = first { CODE } LIST

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns the value and stops at the first item to
make the block yield a true value. If no such item exists, returns C<undef>.

=head2 any

   $bool = any { CODE } LIST

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns true and stops at the first item to make
the block yield a true value. If no such item exists, returns false.

=head2 all

   $bool = all { CODE } LIST

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns false and stops at the first item to make
the block yield a false value. If no such item exists, returns true.

=head2 none
=head2 notall

   $bool = none { CODE } LIST
   $bool = notall { CODE } LISt

Same as L</any> and L</all> but with the return value inverted.

=cut

=head1 TODO

More functions from C<List::Util>:

   reduce
   reductions
   pairfirst pairgrep pairmap

Maybe also consider some from L<List::UtilsBy>.

=head1 ACKNOWLEDGEMENTS

With thanks to Matthew Horsfall (alh) for much assistance with performance
optimizations.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
