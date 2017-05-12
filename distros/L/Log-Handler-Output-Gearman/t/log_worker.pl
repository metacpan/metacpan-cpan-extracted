#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib ( "$Bin/../blib/lib", "$Bin/../blib/arch" );

use Gearman::XS qw(:constants);
use Gearman::XS::Worker;

my $filename = shift(@ARGV);

my $worker = new Gearman::XS::Worker;
$worker->add_server( '127.0.0.1', 4731 );

$worker->add_function( "logger", 0, \&logger, '' );

while (1) {
    my $ret = $worker->work();
    if ( $ret != GEARMAN_SUCCESS ) {
        printf( STDERR "%s\n", $worker->error() );
    }
}

sub logger {
    my ($job) = @_;

    my $log = $job->workload();

    open my $fp, ">>$filename" or die $!;
    print $fp "$log";
    close $fp;

    return 1;
}
