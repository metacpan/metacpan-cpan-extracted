#!perl
use 5.006;
use strict;
use warnings;
use Capture::Tiny qw(capture);
use Log::Log4Cli;
use Test::More;

$Log::Log4Cli::LEVEL = 4;

for my $lvl_name (qw(FATAL INFO NOTICE)) {
    for my $status (0, 7) {
        my $text = 'use Log::Log4Cli; die_' . lc($lvl_name) . " undef, $status";
        my ($out, $err, $exit) = capture { system ($^X, '-MLog::Log4Cli', '-e', "$text") };
        my $exp = ($lvl_name eq 'FATAL' and $status == 0) ? 127 : $status;
        is(($exit >> 8), $exp, "die $lvl_name status check ($status)")
    }
}

eval { die_fatal "evaled die_fatal test" };
like($@, qr/^evaled die_fatal test/);

eval { die_info "evaled die_info test" };
like($@, qr/^evaled die_info test/);

eval { die_notice "evaled die_notice test" };
like($@, qr#^evaled die_notice test at t/50-die.t#);

$Log::Log4Cli::LEVEL = 0;

eval { die_fatal undef, 1 };
like($@, qr#^Died at t/50-die.t#);

eval { die_info undef, 1 };
like($@, qr/^Died at/);

eval { die_notice undef, 1 };
like($@, qr/^Died at/);

done_testing();
