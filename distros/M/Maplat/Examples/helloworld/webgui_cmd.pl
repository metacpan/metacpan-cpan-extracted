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

use Maplat::Web;
use Maplat::Web::HelloWorld;
use XML::Simple;
use Time::HiRes qw(sleep usleep);

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat Webgui";
our $VERSION = "2009-12-09";
MaplatLogo($APPNAME, $VERSION);

our $isCompiled = 0;
if(defined($PerlApp::VERSION)) {
    $isCompiled = 1;
}

# ------------------------------------------
# MAPLAT - WebGUI
# ------------------------------------------
#   Command-line Version for Testing
# ------------------------------------------

my $configfile = shift @ARGV;
print "Loading config file $configfile\n";

my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);

$APPNAME = $config->{appname};
print "Changing application name to '$APPNAME'\n\n";
my $isForking = $config->{server}->{forking} || 0;

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig($config->{server}, $isCompiled);

foreach my $module (@modlist) {
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();

# Everything ready to run
$webserver->run();
