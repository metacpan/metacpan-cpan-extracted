#!/usr/bin/perl -w
# init.pl --- 
# Last modify Time-stamp: <Ye Wenbin 2007-09-26 17:00:07>
# Version: v 0.0 2007/09/22 05:30:05
# Author: Ye Wenbin <wenbinye@gmail.com>

use strict;
use warnings;

my $gc = "goocanvas";
my ($dir) = grep {/$gc/} split /\s*-I\s*/, `pkg-config $gc --cflags`;

opendir(DIR, $dir) or die "Can't open directory $dir: $!";
foreach ( readdir(DIR) ) {
    next unless $_ =~ s/\.h$//;
    if ( /png/ ) {
        s/png/PNG/;
    }
    my $out = "../xs/$_.xs";
    (my $mod = $_) =~ s/goocanvas(.*)/'Goo::Canvas::'.ucfirst($1)/e;
    $mod =~ s/::$//;
    (my $pre = $_) =~ s/goocanvas(.*)/goo_canvas_${1}_/;
    $pre =~ s/__$/_/;
    next if -e $out;
    open(FH, ">$out") or die "Can't create file $out: $!";
    print FH <<TPL;
#include "goocanvas-perl.h"

MODULE = $mod		PACKAGE = $mod   PREFIX = $pre

TPL
}

# create_gc();

sub create_gc {
    my $cc = '../xs/Goo.xs';
    return if -e $cc;
    open(FH, ">$cc") or die "Can't create file $cc: $!";
    print FH <<TPL;
#include "goocanvas-perl.h"

MODULE = Goo::Canvas		PACKAGE = Goo::Can

BOOT:
#include "register.xsh"
#include "boot.xsh"
TPL
}
