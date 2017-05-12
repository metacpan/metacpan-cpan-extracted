use strict;
use warnings;
use Test::More tests => 8;
use Log::Handler lhtest1 => 'LOG';

my $COUNT = 0;

ok(1, 'use');

foreach my $logger (qw/lhtest2 lhtest3/) {
    Log::Handler->create_logger($logger);
    ok(1, 'create logger');

    my $log = Log::Handler->get_logger($logger);

    $log->add(forward => {
        forward_to => sub { $COUNT++ },
        maxlevel   => 'info',
    });

    ok(1, 'add screen output');

    $log->info();
    ok(1, 'log');
}

ok($COUNT == 2, "check counter ($COUNT)");

