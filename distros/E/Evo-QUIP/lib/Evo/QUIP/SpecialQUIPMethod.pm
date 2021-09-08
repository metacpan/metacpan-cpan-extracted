package Evo::QUIP::SpecialQUIPMethod;

use parent 'Evo::QUIP::QUIPMethod';

sub new {
	my ($class,$nrows, $ncols) = @_;

        my $self = $class->SUPER::new($nrows,$ncols);

}

1;
