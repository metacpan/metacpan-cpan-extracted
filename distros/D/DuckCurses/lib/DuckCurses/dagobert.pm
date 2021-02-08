package DuckCurses::dagobert;

use parent 'DuckCurses::entity';

sub new {
        my ($class, $x, $y) = @_;
        my $self = $class->SUPER::new ($x,$y, 'd');

}

1;
