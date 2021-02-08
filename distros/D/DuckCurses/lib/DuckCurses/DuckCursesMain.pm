package DuckCurses::DuckCursesMain;

use Curses;
use Timer::Simple ();

sub new {
        my ($class) = @_;
        my $self = {
		level_timer = Timer::Simple->new(), 
        	levelsys => DuckCurses::levelsystem->new,
	};

        $class = ref($class) || $class;

        bless $self, $class;
}

sub init_level_timer {
	my ($self) = @_;

	$self->{level_timer}->start;
}

sub reinit_level_timer {
	my ($self) = @_;

	$self->{level_timer}->restart;
}

### reinit should happen after 500 ms

sub ask_print_screen {
	my ($self) = @_;

	if (my @units = $self->{level_timer}->hms and @units[1] >= 0.5) {
		$self->print_screen;
		$self->reinit_level_timer;
	}

}

sub print_screen {
	my ($self) = @_;

	$self->{levelsys}->print_screen;
}	
	
1;
