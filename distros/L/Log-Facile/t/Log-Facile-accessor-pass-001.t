use strict;
use Test::More qw(no_plan);

use Log::Facile;

ok chdir $ENV{HOME};

my $log_file = './Log-Facile-write.test.tmp.log';
ok unlink $log_file or croak $! if -f $log_file;
ok my $logger = Log::Facile->new($log_file);

ok $logger->set('debug_flag', 1);
is $logger->get('debug_flag'), 1;

ok $logger->set('level_debug', 'DBG');
is $logger->get('level_debug'), 'DBG';

ok $logger->set('level_info', 'INF');
is $logger->get('level_info'), 'INF';

ok $logger->set('level_error', 'ERR');
is $logger->get('level_error'), 'ERR';

ok $logger->set('level_warn', 'WRN');
is $logger->get('level_warn'), 'WRN';

ok $logger->set('level_fatal', 'FTL');
is $logger->get('level_fatal'), 'FTL';

ok $logger->set('date_format', 'yyyymmdd');
is $logger->get('date_format'), 'yyyymmdd';

ok $logger->set($Log::Facile::TEMPLATE, 'DATE', 'aaa');
is $logger->get($Log::Facile::TEMPLATE, 'DATE'), 'aaa';

ok $logger->set($Log::Facile::TEMPLATE, 'MESSAGE', 'something');
is $logger->get($Log::Facile::TEMPLATE, 'MESSAGE'), 'something';

ok $logger->set($Log::Facile::TEMPLATE, 'LEVEL', 'CONST');
is $logger->get($Log::Facile::TEMPLATE, 'LEVEL'), 'CONST';

ok $logger->set($Log::Facile::TEMPLATE, 'NEW_ONE', 'new');
is $logger->get($Log::Facile::TEMPLATE, 'NEW_ONE'), 'new';

ok unlink $log_file or croak $! if -f $log_file;
__END__
