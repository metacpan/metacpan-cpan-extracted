use strict;
use warnings;
use Test::More;
use JQ::Lite;

my $jq = JQ::Lite->new;

my @array = $jq->run_query("[1,2]\n", 'keys');
is_deeply($array[0], [0, 1], 'keys returns array indexes');

my $ok = eval {
    $jq->run_query("null\n", 'keys');
    1;
};
my $err = $@;
ok(!$ok, 'keys on non-object/non-array throws runtime error');
like($err, qr/^keys\(\): argument must be an object or array/, 'runtime error message mentions keys');

done_testing();
