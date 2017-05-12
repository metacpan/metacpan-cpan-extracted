use strict;
use warnings FATAL => "all";
use Test::More;
use Gnuplot::Builder::Script;

{
    my $builder = Gnuplot::Builder::Script->new;
    $builder->set(
        terminal => 'png size 200,200',
        key      => undef,
    );
    is $builder->to_string(), <<EXPECTED;
set terminal png size 200,200
unset key
EXPECTED

    $builder->set(
        arrow => ['1 from 0,0 to 0,1', '2 from 100,0 to 0,100']
    );
    is $builder->to_string(), <<EXPECTED;
set terminal png size 200,200
unset key
set arrow 1 from 0,0 to 0,1
set arrow 2 from 100,0 to 0,100
EXPECTED
}

done_testing;

