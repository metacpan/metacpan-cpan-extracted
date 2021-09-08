package Evo::QUIP::QUIPMethod;

use Evo::QUIP::MatrixNxN;

sub new {
	my ($class, $nrows, $ncols) = @_;

	my $self = { Q => Evo::QUIP::MatrixNxN->new($nrows, $ncols), 
			v => BinaryVectorN->new($nrows), };

        $class = ref($class) || $class;

        bless $self, $class;	
}

### calculation of some sort of Nash equilibrium
sub calculate_xQxT {
	my ($self) = @_;

}

### calculation/setting Q itself 
sub calculate_hermitian {
	my ($self) = @_;

}

1;
