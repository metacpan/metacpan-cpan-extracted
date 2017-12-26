
use Test::More 0.88;

require_ok('Kevin::Commands::Util');
require_ok('Kevin::Command::kevin');
require_ok('Kevin::Command::kevin::jobs');
require_ok('Kevin::Command::kevin::workers');
require_ok('Minion::Worker::Role::Kevin');
require_ok('Kevin::Command::kevin::worker');
require_ok('Mojolicious::Plugin::Kevin::Commands');

done_testing;
