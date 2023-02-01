#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package List::Keywords 0.09;

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
   reduce reductions
);

sub import
{
   shift;
   my @syms = @_;

   foreach ( @syms ) {
      if( $_ eq ":all" ) {
         push @syms, keys %KEYWORD_OK;
         next;
      }

      $KEYWORD_OK{$_} or croak "Unrecognised import symbol '$_'";

      $^H{"List::Keywords/$_"}++;
   }
}

sub B::Deparse::pp_firstwhile
{
   my ($self, $op, $cx) = @_;
   # first, any, all, none, notall
   my $private = $op->private;
   my $name =
      ( $private ==  0 ) ? "first" :
      ( $private ==  6 ) ? "none" :
      ( $private ==  9 ) ? "any" :
      ( $private == 22 ) ? "all" :
      ( $private == 25 ) ? "notall" :
                           "firstwhile[op_private=$private]";

   # We can't just call B::Deparse::mapop because of the possibility of `my $var`
   # So we'll inline it here
   my $kid = $op->first;
   $kid = $kid->first->sibling; # skip PUSHMARK
   my $code = $kid->first;
   $kid = $kid->sibling;
   if(B::Deparse::is_scope $code) {
      $code = "{" . $self->deparse($code, 0) . "} ";
      if($op->targ) {
         my $varname = $self->padname($op->targ);
         $code = "my $varname $code";
      }
   }
   else {
      $code = $self->deparse($code, 24);
      $code .= ", " if !B::Deparse::null($kid);
   }
   my @exprs;
   for (; !B::Deparse::null($kid); $kid = $kid->sibling) {
      my $expr = $self->deparse($kid, 6);
      push @exprs, $expr if defined $expr;
   }
   return $self->maybe_parens_func($name, $code . join(" ", @exprs), $cx, 5);
}

sub B::Deparse::pp_reducewhile
{
   return B::Deparse::mapop(@_, "reduce");
}

=head1 KEYWORDS

=cut

=head2 first

   $val = first { CODE } LIST

I<Since verison 0.03.>

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns the value and stops at the first item to
make the block yield a true value. If no such item exists, returns C<undef>.

   $val = first my $var { CODE } LIST

I<Since version 0.09.>

Optionally the code block can be prefixed with a lexical variable declaration.
In this case, that variable will contain each value from the list, and the
global C<$_> will remain untouched.

=head2 any

   $bool = any { CODE } LIST

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns true and stops at the first item to make
the block yield a true value. If no such item exists, returns false.

   $val = any my $var { CODE } LIST

I<Since version 0.09.>

Uses the lexical variable instead of global C<$_>, similar to L</first>.

=head2 all

   $bool = all { CODE } LIST

Repeatedly calls the block of code, with C<$_> locally set to successive
values from the given list. Returns false and stops at the first item to make
the block yield a false value. If no such item exists, returns true.

   $val = all my $var { CODE } LIST

I<Since version 0.09.>

Uses the lexical variable instead of global C<$_>, similar to L</first>.

=head2 none

=head2 notall

   $bool = none { CODE } LIST
   $bool = notall { CODE } LISt

I<Since verison 0.03.>

Same as L</any> and L</all> but with the return value inverted.

   $val = none my $var { CODE } LIST
   $val = notall my $var { CODE } LIST

I<Since version 0.09.>

Uses the lexical variable instead of global C<$_>, similar to L</first>.

=cut

=head2 reduce

   $final = reduce { CODE } INITIAL, LIST

I<Since verison 0.05.>

Repeatedly calls a block of code, using the C<$a> package lexical as an
accumulator and setting C<$b> to each successive value from the list in turn.
The first value of the list sets the initial value of the accumulator, and
each returned result from the code block gives its new value. The final value
of the accumulator is returned.

=head2 reductions

   @partials = reductions { CODE } INITIAL, LIST

I<Since version 0.06.>

Similar to C<reduce>, but returns a full list of all the partial results of
every invocation, beginning with the initial value itself and ending with the
final result.

=cut

=head1 TODO

More functions from C<List::Util>:

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
