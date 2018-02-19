package Hush::Logger;
use strict;
use warnings;
use Try::Tiny;
use File::Spec::Functions;

use Exporter 'import';
our @EXPORT_OK = qw/debug/;
my $HUSH_CONFIG_DIR     = $ENV{HUSH_CONFIG_DIR} || catdir($ENV{HOME},'.hush');
my $HUSHLIST_CONFIG_DIR = $ENV{HUSH_CONFIG_DIR} || catdir($HUSH_CONFIG_DIR, 'list');

sub debug {
    my ($msg) = @_;
    my $time = localtime();
    my $debug = catfile($HUSHLIST_CONFIG_DIR, 'debug.log');
    open(my $log, '>>', $debug) or barf("Could not open $debug for writing!!!");
    my $stuff = "[$time] [$$] $msg\n";
    #print $stuff;
    print $log $stuff;
    close $log;
}

1;
