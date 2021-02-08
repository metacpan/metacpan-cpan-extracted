package DuckCurses::goon;

use parent 'DuckCurses::entity';

sub new {
        my ($class, $x, $y) = @_;
        my $self = $class->SUPER::new ($x,$y, 'g');

	$self->{collidable} = "ok";
}

1;
