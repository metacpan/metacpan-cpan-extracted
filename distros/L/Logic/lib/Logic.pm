package Logic;

use 5.006001;
use strict;
no warnings;

our $VERSION = 0.02;

=head1 NAME

Logic - logical programming and multimethod dispatch

=head1 SYNOPSIS

    use Logic::Easy;

    my ($X, $Y);
    
    # UNIFICATION
    Logic-> is(var $X, 2) -> bind($X);
    print $X;  # 2

    Logic-> is(var $X, [1, var $Y]) -> is([1, 2], $X) -> bind($X, $Y);
    print "@$X, $Y";  # 1 2, 2

    # CONS
    Logic-> is([1, 2, 3], cons(var $X, var $Y)) -> bind($X, $Y);
    print "$X, @$Y";  # 1, 2 3

    # ANY
    Logic-> is(var $X, any(1,2,3)) -> is($X, 4) -> bind($X);  # fail!

    # MULTIMETHODS
    no warnings 'redefine';

    sub process : Multi(process) {
        SIG [];
        print "No parameters!";
    }
    sub process : Multi(process) {
        SIG [$x] where { UNIVERSAL::isa($x, 'Cat') };
        print "Got a cat!";
    }
    sub process : Multi(process) {
        SIG cons($x, $xs);
        print "Got $x";  process($xs);
    }

    # RULES
    sub man {
        Logic-> any(
            Logic-> is([@_], 'adam'),
            Logic-> is([@_], 'peter'),
        );
    }
    sub parent {
        Logic-> any(
            Logic-> is([@_], ['adam', 'peter']),
            Logic-> is([@_], ['eve',  'peter']),
        );
    }
    sub father {
        my ($F, $C) = @_;
        Logic-> rule(sub { man($F) }) -> rule(sub { parent($F, $C) });
    }

=head1 DESCRIPTION

The Logic modules implement a logic programming framework in Perl.  It does all
the magic stuff that prolog does, it just doesn't have as big a standard
library.  But it has a bigger standard library, because it has CPAN. On top of
being able to do logic programming without stepping outside the safe (?) world
of Perl syntax, you can do pattern-matching multimethod dispatch with this
module.

=head2 The Easy Life

To get started in 'Prolog with Perl' right away, use the C<Logic::Easy> module.
This exports just a few helpful routines, and uses chained method calls for
the rest of the language.

The order of mention here has been optimized for the first-time reader, 
minimizing backrefrences.  If you need a general reference, well, that's
why computers have search functions.

=over

=item C<var>

Decalares a logic variable.  Perl 5 introduces a variable the statement
I<after> it is declared, so you generally cannot use this function inline
unless (a) you only mention the variable once in that statement, or (b)
you don't follow it by C<my>.

    var my $X;
    Logic->is($X, 42)->bind($X);   # see below for is and bind
    print $X;   # 42

=item C<vars>

Declares several logic variables at once.  See the comments for C<var>.

    vars my ($X, $Y);
    Logic->is($X, $Y)->is($Y, 42)->bind($X, $Y);
    print "$X, $Y";  # 42, 42

=item C<bind>

Forces evaluation of the whole chain, while mutating the given variables (which
must be lvalues) into regular perl values.  The function itself must be the
last thing in a chain, since it does not return a chainable value.

If called in void context, the function dies if the chain fails.  If called
in any other context, it returns undef (or the empty list if in list context)
upon failure and C<1> upon success.  It is fairly common to see a chain
start with C<!> in order to say "I don't care whether this fails", by imposing
boolean context.  If the function fails, none of the variables in the list
is changed.

If the variables cannot be resolved, they are resolved as much as possible in
terms of other variables, which will be references of class C<Logic::Variable>.

    var my $X;
    Logic->fail->bind($X);         # die
    !Logic->fail->bind($X);        # do nothing
    Logic->is($X, 42)->bind($X);   # $X is now 42
    var $X;                        # make $X into a variable again
    Logic->is($X, [$Y])->bind($X); # $X is now [Logic::Variable=HASH(...)]

=item C<all>

Requires that all of its arguments (which are also Logic chains) succeed,
and evaluates them in order.  This function is generally redundant and
useless.

    Logic->id->fail;                     # this can also be written
    Logic->all(Logic->id, Logic->fail);  # like this

=item C<any>

Evaluates its arguments (which are Logic chains) until one of them succeeds.

    Logic->any(
        Logic->is(20, $X),
        Logic->is(20, $Y),
    )->bind;   # succeeds if $X is 20 or $Y is 20

=item C<assert>

Asserts that a condition given by code is true.  Optionally takes a list
of variables to bind for the duration of the block before the block argument.

    Logic->is($X, 20)->assert($X, sub { $X < 10 })->bind;  # fails

You have to specify the variables to bind, otherwise you'll be comparing
against references.  Variables that are still in terms of other, unresolvable
variables cause the assertion to automatically fail.

=item C<id>

Always succeeds.

=item C<fail>

Always fails.

=item C<block>

I<Always> succeeds.  Differs from C<id> in that it even succeeds on
backtracking.  Note that a chain with this as its first element will never
fail, possibly causing an infinite loop.  Use with caution.  Generally
used with C<assign>, and with user input.

=item C<rule>

Executes a block of code and interprets it as another Logic chain to be
nested in the current chain.  This is how you perform recursion.

    sub ancestor {
        my ($A, $B) = @_;
        var my $X;
        Logic->any(
            Logic->rule(sub { parent($A, $B) }),
            Logic->rule(sub { parent($A, $X) })->rule(sub { ancestor($X, $B) }),
        );
    }

=item C<is>

Data structure unification: succeeds if its arguments are equal, binding
variables along the way trying to make the structures equal.

    vars my ($X, $Y);
    Logic->is([$X, 2, 3], [1, 2, $Y])->bind($X, $Y);
    print "$X, $Y";   # 1, 3

Compares stringwise for two non-references.  If the arguments are arrays,
recursively unifies them elementwise.  If they are other references, then
delegates the decision to a C<unify> method if one exists on either argument.
If neither argument has a C<unify> method, then compares them numerically
(effectively testing whether they are exactly the same reference, unless
one of them has the == operator overloaded).  See C<Logic::Data::Cons>
for an example of a C<unify> method.

=item C<assign>

Executes some code and unifies the given variable(s) (given before the code)
with the return value(s) of the block.  If the block returns too few values for
the number of variables, unifies the remaining ones with C<undef>.  If the
block returns too many values, it ignores them.

    var my $X;
    Logic->block
         ->assert(sub { print "Enter a number less than 10: " })
         ->assign($X, sub { scalar <> }),
         ->assert($X, sub { $X < 10 })
         ->bind($X);
    print "You entered $X";

=item C<for>

Unifies the given variable with each of the given values.

    var my $X;
    !Logic->for($X, 1..10)->assert($X, sub { print $X })->fail->bind;
    # prints 12345678910

=item C<cons>

Not a chained method, but an exported sub.  Creates a cons object, which
represents the first element concatenated on the front of the second element,
which is an array.

    vars my ($X, $Y);
    Logic->is(cons($X, $Y), [1,2,3,4,5])->bind($X, $Y);
    print "$X | @$Y";  # 1 | 2 3 4 5

=back

=head2 Multimethods

Now that you're familiar with these basic predicates, you can forget about
them.  The multimethod functionality of C<Logic::Easy> defines some syntactic
sugar around all of this

Every variant should be declared with the :Multi(name) attribute, like:

    sub foo : Multi(foo) {
        # variant 1
    }
    sub foo : Multi(foo) {
        # variant 2
    }

The actual subs I<can> be named differently, but I'd recommend against it.  The
names given to Multi are global, so you can define methods on your objects
in their own packages as multis, and they will work correctly.

How do you specify the signatures of these multimethods?  On the next line,
B<in exactly one line>, using the C<SIG> syntax.  Yes, it's implemented
with a source filter.  Don't sweat though, it's a very safe, non-intrusive
one.

C<SIG> takes a data structure of variables (which are declared C<var> for you),
usually an anonymous array that corresponds to C<[@_]>.  C<[@_]> is unified
against that list, and if it succeeds, then your method is run.  For example:

    sub foo : Multi(foo) {
        SIG [$x, [$y]];
        # only takes a single-element array as its second argument
        # ...
    }

C<SIG> takes an optional C<where> clause:

    sub pow : Multi(pow) {
        SIG [$x, $y] where { $y == 2 };
        $x * $x;
    }
    sub pow : Multi(pow) {
        SIG [$x, $y];
        $x ** $y;
    }

The methods are tried in order of definition.  The SIG argument doesn't
have to be an anonymous array though; it just has to represent one:

    sub first : Multi(first) {
        SIG cons($x, $y);
        $x;
    }

If you need more mad chaining power, then you can no longer use the 
C<SIG> syntactic sugar.  Instead, use the C<sig> semantic sugar:

    sub first : Multi(first) {
        vars my ($x, $y);
        Logic->sig(cons($x, $y))->bind($x);
        $x;
    }

You can chain C<sig> in with whatever else you like.  Keep in mind that
it peeks at your C<@_> array, so don't abstract too much.

=head2 Down a little deeper

So what if there's something you want that's not in the small library I've
given you?  Well, you could ask me, but that's not going to be very time-
efficient.  It turns out, that by conforming to a simple interface, you
can write your own predicates.  An object that can be used as a predicate
must have the following interface:

    sub create;  # ($self, $stack, $state)

This method, in turn, returns another object that represents a "predicate
in progress", which must conform to the following interface:

    sub enter;      # ($self, $stack, $state)
    sub backtrack;  # ($self, $stack, $state)
    sub cleanup;    # ($self, $stack, $state)

Most commonly, C<create> just returns C<$self> and does nothing else.

The C<enter> method is called right after the object was C<create>d, and 
is used for the initial setup for the state.  If it returns a true value,
then the engine moves on into the next prediciate in the chain.  If it returns
false, this predicate is aborted and the engine moves to the previous
predicate in the chain.

The C<backtrack> method is called (if C<enter> succeeded) after the next
predicate in the chain fails, if that ever happens.  Again, if it returns
a true value, the engine assumes that you changed something and moves forward.
If it returns a false value, then your predicate has failed and the engine
moves backward.

The C<cleanup> method is called whenever your predicate fails.  This
is rarely used in a garbage-collecting language like Perl, but alas, it
does need to be used once in a while.  This is mostly for popping scopes
in the C<Logic::Data::Unify> predicate.

The three values that are passed in to all of these methods are as follows:

=over

=item $self

The current object, of course.

=item $stack

The C<Logic::Data::Stack> object, which you will use for calling
sub-predicates.  Call the C<descend> method on this to descend into another
layer.  This should generally be called as the last method in your routine (the
stack continues processing I<after> your routine exits, so any cleanup code
should go in C<cleanup> or at the beginning of C<backtrack>). 

    sub TwoIsTwo::enter {
        my ($self, $stack, $state) = @_;
        $stack->descend(
            Logic::Data::Unify->new(2, 2),
        );
    }

=item $state

Short for C<$stack->state>.

=back

In order to "splice" these objects back in your chain, you have to return
them from the block given to C<rule>.

=head1 BUGS

It is not fully documented yet.  There are other bugs for sure, but I don't
know about them.  Bug reports very welcome.

C<Logic> currently just returns the string C<Logic::Easy>, so if you want
to use the "easy" interface without importing anything, you have to say
Logic::Easy->... .  What a pain.

=head1 SEE ALSO

L<AI::Prolog>

=head1 AUTHOR

Luke Palmer <luke at luqui dot org> 
