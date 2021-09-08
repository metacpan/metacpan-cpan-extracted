package Evo::QUIP::MatrixNxN;

use parent 'Evo::QUIP::MatrixNxNBase';

sub new {
	my ($class, $nrows, $ncols) = @_;

        my $self = $class->SUPER::new($nrows, $ncols);

}

1;
