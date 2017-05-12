#!/usr/bin/perl -w

# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

use strict;
use warnings;

BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}

use Maplat::Worker;
use XML::Simple;

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat Worker";
our $VERSION = "2009-12-09";
MaplatLogo($APPNAME, $VERSION);

our $isCompiled = 0;
if(defined($PerlApp::VERSION)) {
    $isCompiled = 1;
}

my $worker = new Maplat::Worker();
our $cycleStartTime = 0;

# ------------------------------------------
# MAPLAT - Background Worker
# ------------------------------------------
#   Command-line Version for Testing
# ------------------------------------------

my $configfile = shift @ARGV;
print "Loading config file $configfile\n";

my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'directory' ],);

$APPNAME = $config->{appname};
print "Changing application name to '$APPNAME'\n\n";

# set required values to default if they don't exist
if(!defined($config->{mincycletime})) {
    $config->{mincycletime} = 10;
}


my @modlist = @{$config->{module}};

$worker->startconfig($isCompiled);

foreach my $module (@modlist) {
    $worker->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}

$worker->endconfig();

# main loop
$cycleStartTime = time;
while(1) {
    my $workCount = $worker->run();

    my $tmptime = time;
    my $workTime = $tmptime - $cycleStartTime;
    my $sleeptime = $config->{mincycletime} - $workTime;
    if($sleeptime > 0) {
        print "** Fast cycle ($workTime sec), sleeping for $sleeptime sec **\n";
        sleep($sleeptime);
        print "** Wake-up call **\n";
    } else {
        print "** Cycle time $workTime sec **\n";
    }
    $cycleStartTime = time;
}
