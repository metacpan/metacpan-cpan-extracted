#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

my $LAST_EXIT;

BEGIN {
    *CORE::GLOBAL::exit = sub {
        $LAST_EXIT = $_[0];
    };
};

use Log::Log4Cli;
use Test::More;

sub get_logged(&) {
    my $logged;

    no warnings 'uninitialized'; # perl 5.8 fails with 'Use of uninitialized value in open'
    open(LOGGED,'>', \$logged) or die $!;
    log_fd(\*LOGGED);

    $_[0]->();

    close(LOGGED);

    return $logged;
}

for my $sub (\&die_alert, \&die_fatal, \&die_info) {
    for my $status (0, 7) {
        for my $message (undef, 'message') {
            my $logged = get_logged { $sub->($message, $status) };

            if ($sub != \&die_info) {
                like($logged, qr/] .*Exit/);
            } else {
                is($logged, undef);
            }

            is(
                $LAST_EXIT,
                ($sub == \&die_fatal and $status == 0) ? 127 : $status
            );
        }
    }
}

my $logged = get_logged { die };
is($LAST_EXIT, 255);
like($logged, qr| FATAL] Died at t/50-die\.t line \d+\. Exit 255, ET |);

$logged = get_logged { die undef, undef };
is($LAST_EXIT, 255);
like($logged, qr| FATAL] Died at t/50-die\.t line \d+\. Exit 255, ET |);

$logged = get_logged { die "die", "with", "message" };
is($LAST_EXIT, 255);
like($logged, qr| FATAL] die with message at t/50-die\.t line \d+\. Exit 255, ET |);

$Log::Log4Cli::LEVEL = 4;

eval { die_fatal "evaled die_fatal test" };
is($Log::Log4Cli::STATUS, 127);
like($@, qr/^evaled die_fatal test/);

eval { die_info "evaled die_info test" };
is($Log::Log4Cli::STATUS, 0);
like($@, qr/^evaled die_info test/);

$Log::Log4Cli::LEVEL = 0;

eval { die_fatal undef, 42 };
is($Log::Log4Cli::STATUS, 42);
like($@, qr#^Died at t/50-die.t#);

eval { die_info undef, 43 };
is($Log::Log4Cli::STATUS, 43);
like($@, qr/^Died at/);

done_testing();
