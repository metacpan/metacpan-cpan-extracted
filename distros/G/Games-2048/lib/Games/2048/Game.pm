package Games::2048::Game;
use 5.012;
use Moo;

extends 'Games::2048::Board';
with 'Games::2048::Serializable';

has insert_tiles_on_start => is => 'rw', default => 2;
has insert_tiles_on_move  => is => 'rw', default => 1;

has won  => is => 'rw', default => 0;
has goal => is => 'rw', default => 2048;

sub insert_start_tiles {
	my $self = shift;
	return map $self->insert_random_tile, 1..$self->insert_tiles_on_start;
}

sub insert_random_tile {
	my $self = shift;
	my @available_cells = $self->available_cells;
	return if !@available_cells;
	my $cell = $available_cells[rand @available_cells];
	my $value = rand() < 0.9 ? 2 : 4;
	$self->insert_tile($cell, $value);
	$cell;
}

sub insert_tile {
	my ($self, $cell, $value) = @_;
	my $tile = Games::2048::Tile->new(value => $value);
	$self->set_tile($cell, $tile);
	$self->next::method($tile);
}

sub move_tile {
	my ($self, $cell, $next, $next_tile) = @_;
	$self->clear_tile($cell);
	$self->set_tile($next, $next_tile);
}

sub merged_tile {
	my ($self, $cell, $next) = @_;
	my $tile = $self->tile($cell);
	my $next_tile = $self->tile($next);

	my $merged_tile = Games::2048::Tile->new(
		value => $tile->value + $next_tile->value,
		merging_tiles => [ $tile, $next_tile ],
		merged => 1,
	);
}

sub move_tiles {
	my ($self, $vec) = @_;
	my $moved;
	my $move_score = "0 but true";

	my $reverse = $vec->[0] > 0 || $vec->[1] > 0;

	for my $cell ($reverse ? reverse $self->tile_cells : $self->tile_cells) {
		my $tile = $self->tile($cell);
		my $next = $cell;
		my $farthest;
		do {
			$farthest = $next;
			$next = [ map $next->[$_] + $vec->[$_], 0..1 ];
		} while ($self->within_bounds($next)
			and !$self->tile($next));

		if ($self->cells_can_merge($cell, $next)) {
			my $merged_tile = $self->merged_tile($cell, $next);
			$self->move_tile($cell, $next, $merged_tile);
			$move_score += $merged_tile->value;
			$moved = 1;
		}
		elsif (!$self->tile($farthest)) {
			$self->move_tile($cell, $farthest, $tile);
			$moved = 1;
		}
	}

	if ($moved) {
		$_->merged(0) for $self->each_tile;
		$self->next::method($vec);
		return $move_score;
	}
	return;
}

sub move {
	my ($self, $vec) = @_;

	my $move_score = $self->move_tiles($vec);

	if ($move_score) {
		$self->insert_random_tile for 1..$self->insert_tiles_on_move;

		$self->score($self->score + $move_score);
		$self->best_score($self->score) if $self->score > $self->best_score;

		if ($move_score >= $self->goal and !$self->won
			and grep { $_->value >= $self->goal } $self->each_tile)
		{
			$self->win(1);
			$self->won(1);
		}
		if (!$self->has_moves_remaining) {
			$self->lose(1);
		}

		return 1;
	}
	return;
}

sub cells_can_merge {
	my ($self, $cell, $next) = @_;
	my $tile = $self->tile($cell);
	my $next_tile = $self->tile($next);
	$tile and $next_tile and !$next_tile->merged and $next_tile->value == $tile->value;
}

sub has_moves_remaining {
	my $self = shift;
	return 1 if $self->has_available_cells;
	for my $vec ([0, -1], [-1, 0]) {
		for my $cell ($self->each_cell) {
			my $next = [ map $cell->[$_] + $vec->[$_], 0..1 ];
			return 1 if $self->cells_can_merge($cell, $next);
		}
	}
	return;
}

1;
