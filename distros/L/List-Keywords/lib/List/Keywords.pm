#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

package List::Keywords 0.10;

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

=head2 Lexical Variable Syntax

Newly added in I<version 0.09> many of the functions in this module support a
new syntax idea that may be added to Perl core eventually, whereby a lexical
variable can be declared before the code block. In that case, this lexical
variable takes the place of the global C<$_> for the purpose of carrying
values from the input list.

This syntax is currently under discussion for Perl's C<map> and C<grep>
blocks, and may be added in a future release of Perl.

L<https://github.com/Perl/RFCs/pull/33>

=head2 Aliasing and Modification

Each time the block code is executed, the global C<$_> or the lexical variable
being used is aliased to an element of the input list (in the same way as it
would be for perl's C<map> or C<foreach> loops, for example). If the block
attempts to modify the value of this variable, such modifications are visible
in the input list. You almost certainly want to avoid doing this.

For example:

   my @numbers = ...;
   my $x = first my $x { $x++ > 10 } @numbers;

This will modify values in the C<@numbers> array, but due to the short-circuit
nature of C<first>, will only have modified values up to the selected element
by the time it returns. This will likely confuse later uses of the input
array.

Additionally, the result of C<first> is also aliased to the input list, much
as it is for core perl's C<grep>. This may mean that values passed in to other
functions have an ability to mutate at a distance.

For example:

   func( first { ... } @numbers );

Here, the invoked C<func()> may be able to modify the C<@numbers> array, for
example by modifying its own C<@_> array.

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
   ngrep nmap
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

sub deparse_niter
{
   my ($name, $self, $op, $cx) = @_;
   my $targ = $op->targ;
   my $targcount = $op->private;

   # We can't just call B::Deparse::mapop because of the `my ($var)` list
   my $kid = $op->first;
   $kid = $kid->first->sibling; # skip PUSHMARK
   my $block = $kid->first;
   my @varnames = map { $self->padname($_) } $targ .. $targ + $targcount - 1;

   $kid = $kid->sibling;
   my @exprs;
   for(; !B::Deparse::null($kid); $kid = $kid->sibling) {
      my $expr = $self->deparse($kid, 6);
      push @exprs, $expr if defined $expr;
   }

   my $code = "my (" . join(", ", @varnames) . ") {" . $self->deparse($block, 0) . "} "
      . join(", ", @exprs);
   return $self->maybe_parens_func($name, $code, $cx, 5);
}

sub B::Deparse::pp_ngrepwhile { deparse_niter(ngrep => @_) }
sub B::Deparse::pp_nmapwhile  { deparse_niter(nmap  => @_) }

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

=head1 N-AT-A-TIME FUNCTIONS

The following two functions are a further experiment to try out n-at-a-time
lexical variable support on the core C<grep> and C<map> operators. They are
differently named, because keyword plugins cannot replace existing core
keywords, only add new ones.

=head2 ngrep

   @values = ngrep my ($var1, $var2, ...) { CODE } LIST

   $values = ngrep my ($var1, $var2, ...) { CODE } LIST

I<Since version 0.10.>

A variation on core's C<grep>, which uses lexical variable syntax to request a
number of items at once. The input list is broken into bundles sized according
to the number of variables declared. The block of code is called in scalar
context with the variables set to each corresponding bundle of values, and the
bundles for which the block returned true are saved for the resulting list.

In scalar context, returns the number of values that would have been present
in the resulting list (i.e. this is not the same as the number of times the
block returned true).

=cut

=head2 nmap

   @results = nmap my ($var1, $var2, ...) { CODE } LIST

   $results = nmap my ($var1, $var2, ...) { CODE } LIST

I<Since version 0.10.>

A variation on core's C<map>, which uses lexical variable syntax to request a
number of items at once. The input list is broken into bundles sized according
to the number of variables declared. The block of code is called in list
context with the variables set to each corresponding bundle of values, and the
results of the block from each bundle are concatenated together to form the
result list.

In scalar context, returns the number of values that would have been present
in the resulting list.

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
