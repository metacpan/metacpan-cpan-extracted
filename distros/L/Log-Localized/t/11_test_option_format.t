#!/usr/local/bin/perl
#################################################################
#
#   $Id: 11_test_option_format.t,v 1.4 2005/11/07 16:54:00 erwan Exp $
#
#   test format option
#
#   050915 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib ("./t/", "../lib/", "./lib/");
use Utils;

my $log_file;
my $dispatch_file;

BEGIN { 
    eval "use File::Spec";
    plan skip_all => "File::Spec required for testing option dispatchers" if $@;

    plan tests => 5;
    
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
    print DISP "file.format = %m%n\n";
    close(DISP) or die "ERROR: failed to close [$dispatch_file]:$!\n";

    Utils::backup_log_settings();

    my $conf = "".
	"main::* = 2\n".
	"Log::Localized::format = [%PKG]-[%FNC]-[%LIN]-[%LVL]-[%MSG]\n".
        "Log::Localized::dispatchers = $dispatch_file\n";
    Utils::write_config($conf);

    use_ok('Log::Localized');
};

my $want_rules = { "main::*" => 2 };
my %rules = Log::Localized::_test_verbosity_rules();
is_deeply(\%rules,$want_rules,"checking that rules were properly loaded");	  

# log 1 message
sub test {
    llog(1,"that should be logged");
}

test();

# check message formatting in log file
ok(-f $log_file,"check that log file exists");
open(LOG,"$log_file") or die "ERROR: failed to open log file [$log_file]:$!\n";
my $lines = 0;
my $txt = "";
while(my $line = <LOG>) {
    chomp $line;
    $lines++;
    $txt = $line;
}
close(LOG) or die "ERROR: failed to close log file [$log_file]:$!\n";

is($lines,1,"checked logged only 1 line");
is($txt,"[main]-[test]-[60]-[1]-[that should be logged]","check all tags were properly substituted");

unlink $dispatch_file;
unlink $log_file;

Utils::remove_config();
Utils::restore_log_settings();
