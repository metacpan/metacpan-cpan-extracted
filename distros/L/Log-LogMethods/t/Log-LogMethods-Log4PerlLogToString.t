use Modern::Perl;

use Test::More qw(no_plan);
my $class='Log::LogMethods::Log4perlLogToString';
require_ok($class);
use_ok($class);

done_testing;

