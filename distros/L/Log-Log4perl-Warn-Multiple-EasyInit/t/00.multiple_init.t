use strict;
use warnings;
use Test::More;
use Test::Warn;

use FindBin::libs;

BEGIN {
    use Log::Log4perl::Warn::Multiple::EasyInit;
}

warnings_are {
    use_ok('foo');
} [], q{no warnings using foo};

warnings_like {
    use_ok('bar');
} [
    qr{Log::Log4perl already initialised with easy_init\(\) \[at.+?/t/lib/foo.pm, line 6\] at .+?/t/lib/bar.pm line 6},
], q{warnings loading bar};

warnings_like {
    use_ok('baz');
} [
    qr{Log::Log4perl already initialised with easy_init\(\) \[at.+?/t/lib/foo.pm, line 6\] at .+?/t/lib/quux.pm line 6},
    qr{Log::Log4perl already initialised with easy_init\(\) \[at.+?/t/lib/foo.pm, line 6\] at .+?/t/lib/baz.pm line 8},
], q{multiple warnings loading baz};

# no warning now everything is loaded
foreach my $module (qw/foo bar baz quux/) {
    warnings_are {
        use_ok($module);
    } [], qq{no warnings using $module};
}

done_testing;
