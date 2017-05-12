#
# $Id: catalog.t,v 0.70 2005/08/09 15:47:00 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
use lib "t";
use AskGetFileInfo;
my $Debug = $ARGV[0] || 0;
BEGIN { plan tests => 7 };

use MacOSX::File::Catalog;
ok(1); # If we made it this far, we're ok.

my $catalog = MacOSX::File::Catalog->get($0);
$catalog ? ok(1) : ok(0);

use Devel::Peek;
$Debug and Dump $catalog;

use File::Copy;
copy($0, "dummy");

$catalog->finderInfo('TEXT', 'ttxt');
$catalog->lock;

setcatalog($catalog, "dummy") ? ok(1) : ok(0);
my $asked = askgetfileinfo("dummy");
$asked eq "avbstcLinmed" ? ok(1) : ok(0);
$Debug and warn $asked ;
$Debug and Dump $catalog;
unlink "dummy";
$! ? ok(1) : ok(0);
$Debug and warn $!;
$! = 0;
$catalog->unlock;
my $n = setcatalog($catalog, "dummy") ? ok(1) : ok(0);
$Debug and warn $n;
unlink "dummy" ? ok(1) : ok(0);
$Debug and warn $!;
$Debug or unlink "dummy";
