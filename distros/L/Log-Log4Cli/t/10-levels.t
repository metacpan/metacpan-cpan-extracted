#!perl
use 5.006;
use strict;
use warnings;
use Capture::Tiny qw(capture);
use Log::Log4Cli;
use Test::More;

use lib "t";
use _common qw($LVL_MAP);

for my $lvl (-2 .. 5) {
    $Log::Log4Cli::LEVEL = $lvl;

    # log
    for my $lvl_name (keys %{$LVL_MAP}) {
        my ($out, $err) = capture { eval "log_" . lc($lvl_name) . "{ '$lvl_name log msg' }" };
        is($out, '', "log writes to STDERR only (STDOUT must remain empty!)");
        if ($lvl > $LVL_MAP->{$lvl_name}) {
            my $exp = $lvl > 4 ? qr/] \(eval \d+\).* $lvl_name log msg$/ : qr/] $lvl_name log msg$/;
            like($err, $exp, "match log message");
        } else {
            is($err, '', "log_" . lc($lvl_name) . "must remain silent on $lvl level");
        }
    }

    # die
    for my $lvl_name (qw(FATAL INFO NOTICE)) {
        my $cmd = 'use Log::Log4Cli; $Log::Log4Cli::LEVEL = ' . $lvl .
            '; die_' . lc($lvl_name) . " '$lvl_name die msg', 123";
        my ($out, $err) = capture { system($^X, "-MLog::Log4Cli", "-e", $cmd) };
        is($out, '', "die writes to STDERR only (STDOUT must remain empty!)");
        if ($lvl > $LVL_MAP->{$lvl_name}) {
            like($err, qr/$lvl_name/, "match die message");
        } else {
            is($err, '', "die_" . lc($lvl_name) . "must remain silent on $lvl level");
        }
    }
}

done_testing();
