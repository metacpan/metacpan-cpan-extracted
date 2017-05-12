#!/usr/local/bin/perl

#
# Unit test for File::Policy
#
# -t Trace
# -T Deep trace
#

BEGIN { 
	unshift @INC, "../lib", "./lib";
	$^W = 0; #Stop overriding constant raising a warning
}

use strict; 
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;

use vars qw($opt_t $opt_T);
getopts("tT");
plan tests;

#Move into the t directory
chdir('t') if(-d 't');

#Compilation
require File::Policy::Config; #./lib/File/Policy/Config.pm
*File::Policy::Config::IMPLEMENTATION = sub() {"Default"}; #Override the value set in the config module
require File::Policy; #../lib/File/Policy.pm
ASSERT($INC{'File/Policy.pm'}, "Compiled File::Policy version $File::Policy::VERSION");

#Tracing
import Log::Trace qw(print) if($opt_t);
import Log::Trace ('print' => {Deep => 1}) if($opt_T);

#Test fully qualified interface
import File::Policy;
no strict 'refs';
my %stash = %{'File::Policy::'};
ASSERT(scalar(grep {$stash{$_}} qw(check_safe get_log_dir get_temp_dir)) == 3, "available in package");

#Test exports
import File::Policy qw(:all);
%stash = %{'::'};
#DUMP(\%stash);
ASSERT(scalar(grep {$stash{$_}} qw(check_safe get_log_dir get_temp_dir)) == 3, "exported");

#Test default implementation
$ENV{TEMP}="tmp";
ASSERT(get_temp_dir() eq "tmp", "get_tmp_dir");
$ENV{LOGDIR}="logdir";
ASSERT(get_log_dir() eq "logdir", "get_log_dir");
my $rv = eval {check_safe("\x00",'r')};
TRACE($rv, $@);
ASSERT($rv && !$@, "check_safe");
