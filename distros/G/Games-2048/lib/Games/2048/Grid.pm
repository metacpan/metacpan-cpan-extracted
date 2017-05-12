package Games::2048::Grid;
use 5.012;
use Moo;

has size   => is => 'ro', default => 4;
has _tiles => is => 'lazy';

sub _build__tiles {
	my $self = shift;
	[ map [ (undef) x $self->size ], 1..$self->size ];
}

sub each_cell {
	my $self = shift;
	map {
		my $y = $_;
		map [$_, $y], 0..$self->size-1;
	} 0..$self->size-1;
}

sub each_tile {
	my $self = shift;
	map $self->tile($_), $self->tile_cells;
}

sub tile_cells {
	my $self = shift;
	grep $self->tile($_), $self->each_cell;
}

sub available_cells {
	my $self = shift;
	grep !$self->tile($_), $self->each_cell;
}

sub has_available_cells {
	my $self = shift;
	!!scalar $self->available_cells;
}

sub within_bounds {
	my ($self, $cell) = @_;
	$cell->[0] >= 0 and $cell->[0] < $self->size and
	$cell->[1] >= 0 and $cell->[1] < $self->size;
}

sub tile {
	my ($self, $cell) = @_;
	return if !$self->within_bounds($cell);
	$self->_tiles->[$cell->[1]][$cell->[0]];
}

sub clear_tile {
	my ($self, $cell) = @_;
	$self->_tiles->[$cell->[1]][$cell->[0]] = undef;
}

sub set_tile {
	my ($self, $cell, $tile) = @_;
	$self->_tiles->[$cell->[1]][$cell->[0]] = $tile;
}

1;
