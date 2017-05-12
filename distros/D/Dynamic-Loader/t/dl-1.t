#!/usr/bin/env  perl
use strict;

use Test::More tests => 4;
use File::Basename;
use File::Temp qw(tempdir);
use Env::Path;

my $fconfig=dirname($0);

our $JAVAPERL = Env::Path->JAVAPERL;
$JAVAPERL->Prepend("$ENV{PWD}/t");
use_ok('Dynamic::Loader' );

print "JAVAPERL='$ENV{PWD}/t' perl scripts/dynamicloader.pl module.pl --a=A --b=B";
my $ret=int(system("perl scripts/dynamicloader.pl module.pl --a=A --b=B")/256);
ok($ret==123, "perl scripts/dynamicloader.pl module.pl --a=A --b=B");
my $l=Dynamic::Loader::getScript("module.pl");
ok($l=~/\/module.pl/, "looking for $l");
$l=Dynamic::Loader::getLongScript("module.pl");
ok($l=~/-I.*Dynamic-Loader/,"looking for $l");