package Games::Dice::Loaded;
{
  $Games::Dice::Loaded::VERSION = '0.002';
}
use Moose 2.0300;
use List::Util qw/max sum/;

# ABSTRACT: Perl extension to simulate rolling loaded dice

# Keith Schwarz's article is lovely and has lots of pretty diagrams and proofs,
# but unfortunately it's also very long. Here's the tl;dr:

# Draw a bar chart of the probabilities of landing on the various faces, then
# throw darts at it (by picking X and Y coordinates uniformly at random). If
# you hit a bar with your dart, choose that face. This works OK, but has very
# bad worst-case behaviour; fortunately, it's possible to cut up the taller
# bars and stack them on top of the shorter bars in such a way that the area
# covered is exactly a (1/n) \* n rectangle. Constructing this rectangular
# "dartboard" can be done in O(n) time, by maintaining a list of short (less
# than average height) bars and a list of long bars; add the next short bar to
# the dartboard, then take enough of the next long bar to fill that slice up to
# the top. Add the index of the long bar to the relevant entry of the "alias
# table", then put the remainder of the long bar back into either the list of
# short bars or the list of long bars, depending on how long it now is.

# Once we've done this, simulating a dice roll can be done in O(1) time:
# Generate the dart's coordinates; which vertical slice did the dart land in,
# and is it in the shorter bar on the bottom or the "alias" that's been stacked
# above it?

# Heights of the lower halves of the strips
has 'dartboard' => ( is => 'ro', isa => 'ArrayRef' );
# Identities of the upper halves of the strips
has 'aliases' => ( is => 'ro', isa => 'ArrayRef' );
has 'num_faces' => ( is => 'ro', isa => 'Num' );

# Construct the dartboard and alias table
around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	# scale so average weight is 1
	my @weights = @_;
	my $n = scalar @weights;
	my $scalefactor = $n / sum(@weights);
	my $i = 0;
	@weights = map { [$i++, $scalefactor * $_] } @weights; 
	my @small = grep { $_->[1] < 1 } @weights;
	my @large = grep { $_->[1] >= 1 } @weights;
	my @dartboard; my @aliases;
	while ((@small > 0) && (@large > 0)) {
		my ($small_id, $small_p) = @{pop @small};
		my ($large_id, $large_p) = @{pop @large};
		$dartboard[$small_id] = $small_p;
		$aliases[$small_id] = $large_id;
		$large_p = $small_p + $large_p - 1;
		if ($large_p >= 1) {
			push @large, [$large_id, $large_p];
		} else {
			push @small, [$large_id, $large_p];
		}
	}
	for my $unused (@small, @large) {
		$dartboard[$unused->[0]] = 1;
		$aliases[$unused->[0]] = $unused->[0];
	}
	for my $face (0 .. $n - 1) {
		my $d = $dartboard[$face];
		die("Undefined dartboard for face $face") unless defined $d;
		die("Height $d too large for face $face") unless $d <= 1;
		die("Height $d too small for face $face") unless $d >= 0;
	}
	return $class->$orig(
		dartboard => \@dartboard,
		aliases => \@aliases,
		num_faces => $n,
	);
};

# Roll the die
sub roll {
	my ($self) = @_;
	my $face = int(rand $self->num_faces);
	my $height = rand 1;
	my @dartboard = @{$self->dartboard()};
	die("Dartboard undefined for face $face")
		unless defined $dartboard[$face];
	if ($height > $dartboard[$face]) {
		my @aliases = @{$self->aliases};
		return $aliases[$face] + 1;
	} else {
		return $face + 1;
	}
}

*sample = \&roll;

1;

__END__

=head1 NAME

Games::Dice::Loaded - Simulate rolling loaded dice

=head1 SYNOPSIS

  use Games::Dice::Loaded;

  my $die = Games::Dice::Loaded->new(1/6, 1/6, 1/2, 1/12, 1/12);
  my $result = $die->roll();

  my $fair_d4 = Games::Dice::Loaded->new(1, 1, 1, 1);
  $result = $fair_d4->roll();

=head1 DESCRIPTION

C<Games::Dice::Loaded> allows you to simulate rolling arbitrarily-weighted dice
with arbitrary numbers of faces - or, more formally, to sample any discrete
probability distribution which may take only finitely many values. It does this
using Vose's elegant I<alias method>, which is described in Keith Schwarz's
article L<Darts, Dice, and Coins: Sampling from a Discrete
Distribution|http://www.keithschwarz.com/darts-dice-coins/>.

=head1 METHODS

=over

=item new()

Constructor. Takes as arguments the probabilities of rolling each "face". If
the weights given do not sum to 1, they are scaled so that they do. This method
constructs the alias table, in O(num_faces) time.

=item roll()

Roll the die. Takes no arguments, returns a number in the range 1 .. num_faces.
Takes O(1) time.

=item sample()

Synonym for C<roll()>.

=item num_faces()

The number of faces on the die. More formally, the size of the discrete random
variable's domain. Read-only.

=back

=head1 AUTHOR

Miles Gould, E<lt>mgould@cpan.orgE<gt>

=head1 CONTRIBUTING

Please fork
L<the GitHub repository|http://github.com/pozorvlak/Games-Dice-Loaded>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Miles Gould

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

Perl modules for rolling dice:
L<Games::Dice>,
L<Games::Dice::Advanced>,
L<Bot::BasicBot::Pluggable::Module::Dice>,
L<random>.

A Perl module for calculating probability distributions for dice rolls:
L<Games::Dice::Probability>.

Descriptions of the alias method:

=over

=item Michael Vose, L<A Linear Algorithm For Generating Random Numbers with a Given Distribution|http://web.eecs.utk.edu/~vose/Publications/random.pdf>

=item Keith Schwarz, L<Darts, Dice, and Coins: Sampling from a Discrete
Distribution|http://www.keithschwarz.com/darts-dice-coins/>

=item L<Data structure for loaded dice?|http://stackoverflow.com/questions/5027757/data-structure-for-loaded-dice> on StackOverflow

=item L<Wikipedia article|http://en.wikipedia.org/wiki/Alias_method>

=back

=cut
