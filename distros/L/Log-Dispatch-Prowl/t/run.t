use Test::More;
use Log::Dispatch::Prowl;

ok( my $logger = Log::Dispatch::Prowl->new(
        name      => 'spread',
        min_level => 'debug',
        apikey    => 'foobar'),
    'object create');
ok(defined($logger), 'object exists');

done_testing;
