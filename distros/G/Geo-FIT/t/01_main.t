# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 1;
use Geo::FIT;
use File::Temp qw/ tempfile tempdir /;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

$o->file('t/10004793344_ACTIVITY.fit');
$o->open();
my @header = $o->fetch_header;
$o->close();

print "so debugger doesn't exit\n";

