#!/usr/bin/perl -w

# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

use strict;
use warnings;

use Sys::Hostname;

BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}
use Date::Manip qw(Date_Init UnixDate);

sub getClasses($);
sub runCommand(%);
sub runSimpleCommand(%);
sub runService(%);
sub doBuild($);
sub createBuildNumber(%);
sub calcBuildNum();
sub getFileDate();
sub doFPad($$);

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat BUILD";
our $VERSION = "2009-12-09";
MaplatLogo($APPNAME, $VERSION);

my @trimmodules = qw[DBD::CSV DBD::DBM DBD::ExampleP DBD::File DBD::Gofer
                     DBD::NullP DBD::PgPP DBD::ODBC DBD::Sponge unicore/Lbrk.pl];

my @apps;
if(@ARGV) {
    @apps = @ARGV;
} else {
    @apps = qw[webgui worker svc];
    print "Default targets selected.\n";
}

print "The following targets will be build: " . join(" ", @apps) . "\n";

print "Reading classlibs\n";
my @webclasses = getClasses("Maplat::Web");
my @workerclasses = getClasses("Maplat::Worker");

foreach my $app (@apps) {
    doBuild($app);
}

print "Build done.\n";
exit(0);

sub doBuild($) {
    my $app = shift;
    
    print "*** Target: '$app' ***\n";
        
    if($app eq "webgui") {
        print runCommand(
            main    =>  "webgui_cmd.pl",
            base    =>  "MaplatWeb.pm",
            exe     =>  "webgui_cmd.exe",
            mf      =>  "webgui_cmd.exe.manifest",
            classes =>  \@webclasses,
        ) . "\n";
    } elsif($app eq "worker") {
        print runCommand(
            main    =>  "worker_cmd.pl",
            base    =>  "MaplatWorker.pm",
            exe     =>  "worker_cmd.exe",
            mf      =>  "worker_cmd.exe.manifest",
            classes =>  \@workerclasses,
        ) . "\n";
    } elsif($app eq "svc") {
        print runService(
            main    =>  "maplat_svc.pl",
            exe     =>  "maplat_svc.exe",
        ) . "\n";
    } else {
        die("Unknown target '$app'!");
    }
    
}

sub getClasses($) {
    my ($dir) = @_;
    
    my @classes;
    
    my $dirname = $dir;
    $dirname =~ s/\:\:/\//g;
    
    opendir(my $dfh, $dirname) or die($!);
    while((my $fname = readdir($dfh))) {
        next if($fname !~ /\.pm$/);
        $fname =~ s/\.pm//go;
        push @classes, $dir . "::" . $fname;
    }
    closedir $dfh;
    return @classes;
}

sub runCommand(%) {
    my %opts = @_;
    
    my $classes = join(";", @{$opts{classes}});
    if(!defined($classes)) {
        $classes = " ";
    } elsif($classes ne "") {
        $classes = " --add $classes ";
    }

    my $bindfiles = " --bind buildnum[data=" . calcBuildNum . "] ";
    foreach my $classname (@{$opts{classes}}) {
        my $webworker = "";
        my $prefix = "";
        if($classname =~ /\:\:Web\:\:/) {
            $webworker = "Maplat\\Web\\";
            $prefix = "Web_";
        } elsif($classname =~ /\:\:Worker\:\:/) {
            $webworker = "Maplat\\Worker\\";
            $prefix = "Worker_";
        }
        $classname =~ s/.*\:\://g;
        my $dstfname = $prefix . $classname . ".pm";
        my $srcfname = $webworker . $classname . ".pm";
        $bindfiles .= "--bind " . $dstfname . "[file=" . $srcfname . ",text,mode=666] ";
    }
    
    my $cmd = "perlapp " .
              $classes .
              " --norunlib " .
              " --nocompress " .
              " --nologo " .
              " --manifest " . $opts{mf} .
              " --clean " .
                " --trim " . join(";", @trimmodules) . " " .
              " --force " .
              $bindfiles .
              " --exe " . $opts{exe} .
              " " . $opts{main};
    print "Running build command: $cmd\n";
    return `$cmd`;
}

sub runSimpleCommand(%) {
    my %opts = @_;
    
    my $cmd = "perlapp " .
              " --norunlib " .
              " --nocompress " .
              " --nologo " .
              " --clean " .
              " --force " .
              " --bind buildnum[data=" . calcBuildNum . "] " .
              " --exe " . $opts{exe} .
              " " . $opts{main};
    print "Running build command: $cmd\n";
    return `$cmd`;
}

sub runService(%) {
    my %opts = @_;
    
    my $cmd = "perlsvc " .
                " --norunlib ".
                " --nocompress " .
                " --nologo " .
                " --clean " .
                " --force " .
                " --bind buildnum[data=" . calcBuildNum . "] " .
                " --exe " . $opts{exe} .
                " " . $opts{main};
    
    print "Running build command: $cmd\n";
    return `$cmd`;
}

sub calcBuildNum() {
    my $hname = hostname;
    my $ts = getFileDate();
    my $buildnum = $ts . "_" . $hname;
    
    return $buildnum;
}

sub getFileDate() {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$ yday, $isdst) = localtime time;
    $year += 1900;
    $mon += 1;
    
    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    $sec = doFPad($sec, 2);
    return "$year$mon$mday$hour$min$sec";
}

sub doFPad($$) {
    my ($val, $len) = @_;
    while(length($val) < $len) {
        $val = "0$val";
    }
    return $val;
}
