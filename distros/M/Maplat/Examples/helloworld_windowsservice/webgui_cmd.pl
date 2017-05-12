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
use XML::Simple;
use Time::HiRes qw(sleep usleep);

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat Webgui";
our $VERSION = "2009-12-09";
MaplatLogo($APPNAME, $VERSION);
use English;

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

# ugly hack to provide the files usually provided in @INC during run-time
# for the basic maplat framework files (templates, images, javascript). In
# most cases, this is whereever the Maplat framework is unpacked (or installed,
# if perl runtime with installed Maplat is available)
#
# This is only required when running compiled with PerlAPP, but of course, if
# you like to split up your files, just make the usual Maplat/Web/* directory
# structure and add the root directory of it to extraincpaths
my $extraincpaths = $config->{extraincpaths} || "";
my @extrainc = split/\;/, $extraincpaths;

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig($config->{server}, $isCompiled);

foreach my $module (@modlist) {
    $module->{options}->{EXTRAINC} = \@extrainc;
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();

# Everything ready to run
if($isForking && $OSNAME eq 'MSWin32') {
    $webserver->run(lock_file => 'C:\Temp\webgui.lock');
} else {
    $webserver->run();
}
