use strict;
use warnings;

use Test::More;

use Devel::Probe;

exit main();

sub main {
    ok(Devel::Probe::is_installed(), 'initially installed');

    Devel::Probe::install();
    ok(Devel::Probe::is_installed(), 'still installed (noop)');

    Devel::Probe::remove();
    ok(!Devel::Probe::is_installed(), 'not installed after remove');

    Devel::Probe::remove();
    ok(!Devel::Probe::is_installed(), 'still not installed (noop)');

    Devel::Probe::install();
    ok(Devel::Probe::is_installed(), 'installed');

    Devel::Probe::install();
    ok(Devel::Probe::is_installed(), 'still installed (noop)');

    done_testing;
    return 0;
}

