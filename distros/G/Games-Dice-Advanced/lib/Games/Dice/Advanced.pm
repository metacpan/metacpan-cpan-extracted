package Games::Dice::Advanced;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.1';

=head1 NAME

Games::Dice::Advanced - simulate dice rolls, including weird and
loaded dice

=head1 SYNOPSIS

    print Games::Dice::Advanced->roll();     # roll a six-sided die
    print Games::Dice::Advanced->roll('d4'); # roll a four-sided die

    # roll a four-sided die and a 6-sided die and return the total
    $die1 = Games::Dice::Advanced->new('d4');
    $die2 = Games::Dice::Advanced->new('d6');
    print Games::Dice::Advanced->roll($die1, $die2);

    print $die1->roll();                 # roll the d4 we created above

    # roll 2 four-sided dice and a 6-sided die and return the total
    print Games::Dice::Advanced->roll('2d4', 'd6');

    # create a four-sided die with the squares of 1, 2, 3 and 4
    Games::Dice::Advanced->new(sub { int(1+rand(4)) ** 2 });

=head1 METHODS

=over 4

=item roll

Roll one or more dice.  If called as a class method, it first calls
appropriate constructors and creates objects before calling those objects'
roll() methods.  When called on an object it simply rolls the die.

When called as a class method, it takes a list of arguments defining a
'recipe' to roll.  These are added
together to produce a result.  Each item in the recipe must be a valid
argument to the constructor (see the description of the 'new' method below).
If no argument is given to a class method, we assume a six-sided die - 'd6'.
You will note that the multiplier constructor is not available when roll
is called in this way.

When called as an object method, no arguments are permitted.

=cut

sub roll {
    my($self, @args) = @_;
    if(ref($self) && $self->isa('Games::Dice::Advanced')) {
        # called as object method
        die("roll() called incorrectly") if(@args);
	    return &{$self};
    } elsif($self eq 'Games::Dice::Advanced') {
        # called as class method
        @args = ('d6') unless(@args);
	    return sum(map {
	        (ref($_) && $_->isa('Games::Dice::Advanced')) ?
	            $_->roll() :
	            Games::Dice::Advanced->new($_)->roll()
	    } @args);
    } else {
        die("Out of cucumber error\n");
    }
}

=item new

This method defines a die.  You may call it yourself to create a die for
later rolling, or it may be called by the roll() method.  It takes zero,
one or two
arguments.  If no argument is given, we silently assume that the user
wants to create a six-sided die, a 'd6'.  Valid arguments are:

=over 4

=item integer constant, eg '5'

Creates a die that always returns that constant

=item dN, where N is integer, eg 'd10'

Creates a die that returns a random integer from 1 to N with results spread
evenly across the range.

=item NdM, where N and M are integer, eg '2d10'

Creates a die dM as above which is rolled N times to generate a result.
Note that the N is *not* just a multiplier.

=item N and any other valid argument, where N is a number, eg (2, 'd4')

Note that the two arguments may be in any order.  Creates a die as specified,
and multiplies the results by N when it is rolled.  Compare with NdM above.

=back

Leading and trailing whitespace is stripped, no other whitespace is allowed
in any of the above.

=over 4

=item SUBREF

A reference to a subroutine, which is to be called whenever we need to generate
a result.  It should take no parameters.

=item HASHREF

Use this to easily specify truly weird dice.  NOT YET IMPLEMENTED, so use
a SUBREF for the moment.

=back

=cut

sub new {
    my($class, @args) = @_;

    @args = ('d6') unless(@args);
    @args = map { s/(^\s+|\s+$)//; $_; } @args;

    my $self = '';

    if(@args == 1) { push @args, 1; } # multiply by 1

    if(@args == 2) {
        my($recipe, $mul) = @args;
	    ($recipe, $mul) = ($mul, $recipe) if(ref($mul) || $mul=~ /\D/);
	    die("Bad arguments to new()") if(ref($mul) || $mul=~ /\D/);

	    if($recipe !~ /\D/) {                       # constant
	        # $self = eval("sub { $recipe * $mul }");
	        $self = sub { $recipe * $mul };
	    } elsif($recipe =~ /^d(\d+)$/) {            # dINT
            # $self = eval("sub { (1 + int(rand($1))) * $mul }");
            my $faces = $1;
            $self = sub { (1 + int(rand($faces))) * $mul };
	    } elsif($recipe =~ /^(\d+)d(\d+)/) {        # INTdINT
	        my($repeats, $faces) = ($1, $2);
	        $self = sub {
	            $mul * sum(map { 1 + int(rand($faces)) } (1..$repeats))
	        };
	    } elsif(ref($recipe) eq 'CODE') {
	        $self = sub { $mul * &{$recipe} }
	    } else {
	        die("$recipe isn't valid");
    	}
    } else {
        die("new() called incorrectly");
    }

    bless($self, $class);
}

=back

=cut

sub sum { foldl(sub { shift() + shift(); }, @_); }

sub foldl {
  my($f, $z, @xs) = @_;
  $z = $f->($z, $_) foreach(@xs);
  return $z;
}

=head1 BUGS

For random, read 'pseudo-random'.  Patches to work with sources of true
randomness are welcome.

Doesn't support dice with fractional or complex numbers of sides :-)

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism.  And,
while this is free software (both free-as-in-beer and free-as-in-speech) I
also welcome payment.  In particular, your bug reports will get moved to
the front of the queue if you buy me something from my wishlist, which can
be found at L<http://www.cantrell.org.uk/david/shopping-list/wishlist>.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT

Copyright 2003 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

1;
