use strict;
use warnings;

use Test::More;

use Devel::Probe;

exit main();

sub main {
    ok(!Devel::Probe::is_enabled(), 'initially enabled');

    Devel::Probe::disable();
    ok(!Devel::Probe::is_enabled(), 'not enabled after disable');

    Devel::Probe::disable();
    ok(!Devel::Probe::is_enabled(), 'still not enabled (noop)');

    Devel::Probe::enable();
    ok(Devel::Probe::is_enabled(), 'enabled');

    Devel::Probe::enable();
    ok(Devel::Probe::is_enabled(), 'still enabled (noop)');

    done_testing;
    return 0;
}

