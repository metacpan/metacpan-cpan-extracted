#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);

if ($ENV{'TEST_JIP_DAEMON'}) {
    plan tests => 3;
}
else {
    plan skip_all => 'set TEST_JIP_DAEMON to enable this test (developer only!)';
}

subtest 'Require some module' => sub {
    plan tests => 3;

    use_ok 'JIP::Daemon', '0.03';

    require_ok 'JIP::Daemon';
    is $JIP::Daemon::VERSION, '0.03';

    diag(
        sprintf 'Testing JIP::Daemon %s, Perl %s, %s',
            $JIP::Daemon::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'try_kill()' => sub {
    plan tests => 3;

    is(JIP::Daemon->new->try_kill,    1);
    is(JIP::Daemon->new->try_kill(0), 1);

    local $SIG{'USR1'} = sub { pass 'USR1 caught'; };
    JIP::Daemon->new->try_kill(10);
};

subtest 'status()' => sub {
    plan tests => 1;

    is_deeply [JIP::Daemon->new->status], [$PROCESS_ID, 1, 0];
};

