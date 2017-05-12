use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    my $builder1 = Gnuplot::Builder::Script->new;
    my $builder2 = Gnuplot::Builder::Script->new;
    $builder1->set(
        'style data' => 'lines',
        'style fill' => 'solid 0.5'
    );
    $builder2->set(
        style => ['data lines', 'fill solid 0.5']
    );

    my $exp = <<EXP;
set style data lines
set style fill solid 0.5
EXP
    is $builder1->to_string, $exp;
    is $builder2->to_string, $exp;
}

done_testing;

