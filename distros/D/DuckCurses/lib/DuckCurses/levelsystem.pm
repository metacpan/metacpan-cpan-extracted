package DuckCurses::levelsystem;

### generate a level  

sub new {
	my ($class, $ln) = @_;
	my $self = { levels => {}, current_level_number => $ln or 1, };

	$self->{levels}{1} = DuckCurses::level1->new(0,0);
	$self->{levels}{2} = DuckCurses::level2->new(0,0);

	$class = ref($class) || $class;
	bless $self, $class;
}

sub print_screen {
	my ($self) = @_;

	$self->{levels}{$self->{current_level_number}}->print_screen;
}

1;
