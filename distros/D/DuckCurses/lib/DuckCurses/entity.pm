package DuckCurses::entity;

sub new {
	my ($class, $x,$y, $chr) = @_;
	my $self = { x => $x, y => $y,
		character => $chr or 'o',
		collidable => undef,
	};

	$class = ref($class) || $class;

	bless $self, $class;
}

sub move_left {
	my ($self) = @_;

	$self->{x}--;
}

sub move_right {
	my ($self) = @_;

	$self->{x}++;
}

sub jump {
	my ($self) = @_;

	### FIXME
}

sub print_on_screen {
	my ($self, $roomx, $roomy) = @_;

	### FIXME

}
1;
