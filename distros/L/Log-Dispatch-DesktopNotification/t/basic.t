use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Log::Dispatch::DesktopNotification') }

my $log = Log::Dispatch::DesktopNotification->new(
    name  => 'notify', min_level => 'debug',
    title => 'Log::Dispatch::DesktopNotification test',
);

isa_ok($log, 'Log::Dispatch::Output');

eval {
    $log->log(level => 'info', message => 'success');
};
ok(!$@, 'test message');
