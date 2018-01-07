use strict;
use warnings;

use Test::More;
use Test::Fatal;

use IO::Async::Loop;
use Job::Async::Test::Compliance;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $compliance = Job::Async::Test::Compliance->new
);
is(exception {
    ok(my $elapsed = $compliance->test(
        'memory',
        worker => { },
        client => { },
    )->get, 'nonzero elapsed time');
}, undef, 'memory client/worker passed compliance test');

done_testing;

