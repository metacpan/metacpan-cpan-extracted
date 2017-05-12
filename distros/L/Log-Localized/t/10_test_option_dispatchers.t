#!/usr/local/bin/perl
#################################################################
#
#   $Id: 10_test_option_dispatchers.t,v 1.3 2005/11/07 16:49:09 erwan Exp $
#
#   test dispatching to a file
#
#   050914 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

my $log_file;
my $dispatch_file;

BEGIN { 
    eval "use File::Spec";
    plan skip_all => "File::Spec required for testing option dispatchers" if $@;

    plan tests => 6;

    # using Log::Localized with global verbosity off but config file

    $dispatch_file = File::Spec->catfile($ENV{PWD},"dispatch.tmp");
    $log_file = File::Spec->catfile($ENV{PWD},"log.tmp");

    unlink $log_file;

    open(DISP,"> $dispatch_file") or die "ERROR: failed to write to file [$dispatch_file]:$!\n";
    print DISP "dispatchers =  file\n";
    print DISP "\n";
    print DISP "file.class = Log::Dispatch::File\n";
    print DISP "file.min_level = debug\n";
    print DISP "file.filename = $log_file\n";
    print DISP "file.mode = append\n";
    print DISP "file.format = [%d] %m%n\n";
    close(DISP) or die "ERROR: failed to close [$dispatch_file]:$!\n";

    Utils::backup_log_settings();

    my $conf = "".
	"main::* = 2\n".
        "Log::Localized::dispatchers = $dispatch_file\n";
    Utils::write_config($conf);

    use_ok('Log::Localized');
};

my $want_rules = { "main::*" => 2 };
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

#diag("calling llog");
llog(0,"that should be logged 0");
llog(2,"that should be logged 2");
llog(3,"that shouldnot be logged 3");

#diag("checking that llog() was properly dispatched");
ok(-f $log_file,"check that log file exists");
open(LOG,"$log_file") or die "ERROR: failed to open log file [$log_file]:$!\n";
my $lines = 0;
my $txt = "";
while(my $line = <LOG>) {
    chomp $line;
    $lines++;
    $txt.="----".$line;
}
close(LOG) or die "ERROR: failed to close log file [$log_file]:$!\n";

is($lines,2,"checked logged only 2 lines");
ok($txt =~ /\[main::main\(\) l.\d+\] \[LEVEL 0\]: that should be logged 0/,"check first log line");
ok($txt =~ /\[main::main\(\) l.\d+\] \[LEVEL 2\]: that should be logged 2/,"check second log line");

unlink $dispatch_file;
unlink $log_file;

Utils::remove_config();
Utils::restore_log_settings();
