package Lingua::Identifier::ForwardProp;
$Lingua::Identifier::ForwardProp::VERSION = '0.01';
use 5.006;
use strict;

use Math::Matrix::MaybeGSL;

sub sigmoid {
    my $matrix = shift;
    return $matrix->each( sub { 1 / ( 1 + exp( - shift)) } );
}

sub forward_prop {
    my ($x, $Thetas) = @_;

    my $a = [];
    $a->[0] = $x;

    for my $i (1 .. scalar(@$Thetas)) {
        my $m = Matrix->new(1,1);
        $m->assign(1,1,1);
        my $z = $Thetas->[$i-1] * $m->vconcat($a->[$i-1]);
        $a->[$i] = sigmoid($z);
    }

    return $a->[-1];
}


=for Pod::Coverage sigmoid forward_prop

=cut

1;


