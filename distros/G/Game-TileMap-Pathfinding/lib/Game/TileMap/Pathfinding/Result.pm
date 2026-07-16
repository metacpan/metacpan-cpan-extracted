package Game::TileMap::Pathfinding::Result;
$Game::TileMap::Pathfinding::Result::VERSION = '0.002';
use v5.14;
use warnings;

sub new
{
	return bless $_[1], $_[0];
}

sub next_step
{
	return splice @{$_[0]}, 0, 2;
}

sub step_count
{
	return @{$_[0]} / 2;
}

sub steps
{
	my ($self) = @_;

	my @all;
	for my $i (map { $_ * 2 } 0 .. $self->step_count - 1) {
		push @all, [@{$self}[$i, $i + 1]];
	}

	return @all;
}

1;

__END__

=head1 NAME

Game::TileMap::Pathfinding::Result - Pathfinding result object

=head1 SYNOPSIS

	while (my ($x, $y) = $result->next_step) {
		...
	}

=head1 DESCRIPTION

This is a lightweight blessed object which represents a result of successful
pathfinding. The underlying reference is an array of C<2n> elements, where C<n>
is the number of steps.

Each step consists of two elements in this array. This array can be accessed
manually, this module only functions as a syntactic sugar. For example, it may
be more convenient (and surely more performant) to avoid using this interface
and use C<for_list> in modern perl instead:

	use v5.42;

	foreach my ($x, $y) ($result->@*) {
		...
	}

=head2 Interface

=head3 new

	$pf_result = $class->new($array_ref)

Returns a new instance of this class. This is done automatically in
L<Game::TileMap::Pathfinding/find_path>.

=head3 next_step

	($x, $y) = $pf_result->next_step()

This removes the first coordinate pair from the underlying array and returns x
and y integers. Can be called in loop until it starts to return C<undef>s.

=head3 steps

	@all_steps = $pf_result->steps()

This method returns all steps as an array of two-element array references. This
is less efficient because of the extra arrays created, and does not mix with
L</next_step>. However, can come in handy in certain scenarios.

=head3 step_count

	$count = $pf_result->step_count()

This returns the number of steps needed to reach the destination. This will be
reduced by C<1> after each call to L</next_step>, and when it reaches C<0>, the
destination has been reached.

=head1 SEE ALSO

L<Game::TileMap::Pathfinding>

