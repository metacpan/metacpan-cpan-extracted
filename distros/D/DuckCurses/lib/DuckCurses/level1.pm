package DuckCurses::level1;

use parent 'DuckCurses::level';

sub new {
        my ($class, $x, $y) = @_;
        my $self = $class->SUPER::new ($x,$y);

	### add enemies to the entities list
	$self->add_entity(DuckCurses::goon->new(20,10));	

	$self->init;

}

sub update {
	my ($self, $level_timer) = @_;

	if (my @units = $level_timer->hms and @units[1] >= 0.500) {
		$self->move_left;
		return "ok";
	} else {
		return undef;
	}
}

1;
