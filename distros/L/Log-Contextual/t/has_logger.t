use strict;
use warnings;

use Log::Contextual::SimpleLogger;
use Test::More;
use Log::Contextual qw(:log set_logger has_logger);

my $log = Log::Contextual::SimpleLogger->new;
ok(!has_logger, 'has_logger returns false when logger unset');
set_logger $log;
ok(has_logger, 'has_logger returns true when logger set');

done_testing;
