#!/usr/bin/perl

use warnings;
use strict;

use FindBin qw($Bin);

use lib "$Bin/../lib";

use Log::Log4perl;

Log::Log4perl::init("$Bin/log.conf");

my $log = Log::Log4perl->get_logger('producer');

my @levels = ('debug', 'info', 'warn', 'error', 'fatal');

my @alpha  = ('A' .. 'Z');
my $prefix = 1;
my $count  = 1;
my $index  = 0;

while ($count < 500) {

    my $method_name = $levels[ int(rand(5)) ];

    my $msg = sprintf('%s', $alpha[$index]) x $prefix;

    $index++;

    if ($index == 25) {
        $count++;
        $index = 0;
        $prefix++;
    }

    {
        no strict 'refs'; ## no critic

        $log->$method_name($msg);
    }

    sleep(sprintf('%.1f', rand(1)));
}
