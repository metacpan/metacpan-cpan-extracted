use Test::More 'no_plan';
use Test::Fatal;

use_ok 'Linux::Systemd::Daemon', qw/sd_notify sd_ready/;

is exception { sd_notify(ready => 1) }, undef, 'sent notification';

is exception { sd_ready() }, undef, 'sent ready notification';

done_testing;
