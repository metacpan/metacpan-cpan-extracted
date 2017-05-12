use strict;
use warnings;

use File::Temp qw/tempfile tempdir/;;
use Test::More tests => 5;

BEGIN { use_ok( "File::Lockfile"); }

my $tempdir = tempdir(CLEANUP => 1);
my $lockfile = File::Lockfile->new('testname.pid', $tempdir);

ok ( defined $lockfile, "Class instantiation" );

my $pid = $lockfile->check;

ok ( ! defined $pid, "Lockfile shouldn't exist" );

$lockfile->write;
$pid = $lockfile->check;

ok ( $pid eq $$, "Lockfile written" );

$lockfile->remove;
$pid = $lockfile->check;

ok ( !defined $pid, "Lockfile removed");
