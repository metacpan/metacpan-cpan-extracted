#
# $Id: info.t,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
use lib 't';
use AskGetFileInfo;
my $Debug = $ARGV[0] || 0;
BEGIN { plan tests => 10 };

use MacOSX::File;
use MacOSX::File::Info;
ok(1); # If we made it this far, we're ok.

my $finfo = MacOSX::File::Info->get($0);
ok($finfo);

use Data::Dumper;
$Debug and print Dumper $finfo;

use File::Copy;
copy($0, "dummy");

$finfo->type('TEXT');
$finfo->creator('ttxt');
my $attr = $finfo->flags("avbstclinmed");
ok($attr eq "avbstclinmed");
$attr = $finfo->flags(-locked => 1);
ok($attr eq "avbstcLinmed");
ok($finfo->nodeFlags == 1);
ok(setfinfo($finfo, "dummy"));
my $asked = askgetfileinfo("dummy");
ok($asked eq "avbstcLinmed");
$Debug and warn $asked ;
$Debug and print Dumper $finfo;
unlink "dummy";
ok($!);
$Debug and warn $!;
$! = 0;
$finfo->unlock;
my $n;
ok(setfinfo($finfo, "dummy"));
$Debug and warn $MacOSX::File::OSErr;
ok(unlink "dummy");
$Debug and warn $!;

$Debug or unlink "dummy";
