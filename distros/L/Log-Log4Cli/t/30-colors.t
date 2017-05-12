#!perl -T
use 5.006;
use strict;
use warnings;
use Capture::Tiny qw(capture);
use Log::Log4Cli;
use Term::ANSIColor qw(colored);
use Test::More;

use lib "t";
use _common qw($LVL_MAP);

$Log::Log4Cli::COLOR = 1;
$Log::Log4Cli::LEVEL = 4;

for my $name (keys %{$Log::Log4Cli::COLORS}) {
    my ($out, $err) = capture { eval "log_" . lc($name) . "{ '' }" };
    my $got = substr($err, 0, 6);
    my $exp = colored("[", $Log::Log4Cli::COLORS->{$name});
    $exp = substr($exp, 0, 6);
    is($got, $exp, "$name match");
}

done_testing();
