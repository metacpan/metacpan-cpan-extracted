package DuckCurses::enemy;

use parent 'DuckCurses::entity';

sub new {
	my ($class, $x,$y, $chr) = @_;
        my $self = $class->SUPER::new ($x,$y, $chr);

	$class = ref($class) || $class;

	bless $self, $class;
}

1;
