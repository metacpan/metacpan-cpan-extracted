use Test2::V0 -no_srand => 1;
use 5.020;
use Test::Script;

script_compiles 'example/unbundle.pl';

my $out = '';

script_runs     'example/unbundle.pl', { stdout => \$out };

note $out;

done_testing;
