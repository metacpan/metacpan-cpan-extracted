package DuckCurses::level;

### some sort of level room

sub new {
	my ($class, $x,$y) = @_;
	my $self = { x => $x, y => $y, entities => (), };

	$class = ref($class) || $class;

	bless $self, $class;
}

sub init {
	my ($self, $x, $y) = @_;

	$self->{x} = $x or 0;
	$self->{y} = $y or 0;
}

sub reinit {
	my $self = shift;
	my $x = shift;
	my $y = shift;

	$self->init($x,$y);
}

sub move_left {
	my ($self) = @_;

	$self->{x}--;
}

sub move_right {
	my ($self) = @_;

	$self->{x}++;
}

sub move_up {
	my ($self) = @_;

	$self->{y}--;
}

sub move_down {
	my ($self) = @_;

	$self->{y}++;
}

### adding enemies/entities to the level

sub add_entity {
	my ($self, $e) = @_;

	push (@{ $self->{entities} }, $e);
}

sub add_enemy {
	my ($self, $en) = @_;

	push (@{ $self->{entities} }, $en);
}

### print status data (PCs and NPCs) to screen
sub print_screen {
	my ($self) = @_;

	for (my $i = 0; $i < length($self->{entities}); $i++) {
		$self->{entities}->print_on_screen($self->{x}, $self->{y});
	}
}

1;
