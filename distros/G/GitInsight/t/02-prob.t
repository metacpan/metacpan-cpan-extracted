use strict;
use Test::More;
use GitInsight::Util qw(prob);

is sprintf( "%.5f", prob(100,50)), 0.50505, "probability 100/50";
is sprintf( "%.5f", prob(200,100)), 0.50505, "probability 200/100";
is sprintf( "%.5f", prob(100,80)), 0.79798, "probability 100/80";
is sprintf( "%.5f", prob(200,160)), 0.79798, "probability 200/160";
is int(prob(200,200)), 1, "probability 200/200";
done_testing;
