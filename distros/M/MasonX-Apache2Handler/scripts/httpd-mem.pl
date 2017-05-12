#!/usr/bin/perl

use strict;
use warnings;

my $id = $ARGV[0] || 'httpd -k';
my $log_fn = 'httpd-mem.log';

unlink $log_fn;

my $count = 99;
while( 1 ) {
    if( ++$count > 20 ) {
	print_heading();
	$count = 0;
    }
    process();
    sleep 2;
}

close LOG;

sub print_heading
{
    open( LOG, ">>$log_fn" ) || die "$log_fn open: $!\n";
    my %tmem = split /:|\n/, `cat /proc/1/status`;
    for( sort keys %tmem ) {
	next unless /^Vm/;
	printf "%11s",  $_;
	printf LOG "%11s",  $_;
    }
    print "\n";
    print LOG "\n";
    close LOG;
}

sub process
{
    my @pids = `ps aux | grep "$id" | grep -v grep | awk '{ print \$2 }'`;
    chomp for @pids;

    my %tmem = split /:|\n/, `cat /proc/1/status`;
    for( sort keys %tmem ) {
	next unless /^Vm/;
	$tmem{$_} = 0;
    }
    for my $pid (@pids) {
	my %mem = split /:|\n/, `cat /proc/$pid/status`;
	for( sort keys %mem ) {
	    next unless /^Vm/;
	    my( $kb ) = $mem{$_} =~ m/(\d+)/;
	    $tmem{$_} += $kb || 0;
	}
    }
    open( LOG, ">>$log_fn" ) || die "$log_fn open: $!\n";
    for( sort keys %tmem ) {
	next unless /^Vm/;
	printf "%11d", $tmem{$_};
	printf LOG "%11d", $tmem{$_};
    }
    print "\n";
    print LOG "\n";
    close LOG;
}
