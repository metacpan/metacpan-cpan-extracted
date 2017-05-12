#!perl -T
use 5.006;
use strict;
use warnings;
use Capture::Tiny qw(capture);
use Log::Log4Cli;
use Test::More tests => 1;

$Log::Log4Cli::LEVEL = 0;
$Log::Log4Cli::POSITIONS = 1;

my ($out, $err) = capture { eval "log_fatal { '' }" };
like($err, qr/] \(eval \d+\)/, "Positions enabled");
