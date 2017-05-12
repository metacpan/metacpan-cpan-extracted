#!perl -T

# Test the common fuction. Anthony Fletcher

use 5;
use warnings;
use strict;
use Data::Dumper;

use Test::More tests => 34;

$| = 1;

# Tests
BEGIN { use_ok('File::Store'); }

# Test the routine.
my $obj;

ok($obj = new File::Store(), "constructor");
eval {$obj = new File::Store(unkown=>10); }; ok($@, "constructor with bad option");
ok($obj = new File::Store(expire=>3), "constructor with option");

is($obj->count(), 0, "store count correct " . __LINE__ );

my $n = $obj->get('Makefile.PL');
ok($n, "open new file");
is($obj->count(), 1, "store count correct " . __LINE__ );

my $c = $obj->get('Makefile.PL');
ok($c, "open cached file");
ok($n eq $c, "same contents");
is($obj->count(), 1, "store count correct " . __LINE__ );

$obj->clear('Makefile.PL');
ok($obj->count() == 0, "store count correct");

ok($obj->get('Makefile.PL'), "open file after clear");
ok($obj->get('Makefile.PL'), "open cached file");
is($obj->count(), 1, "store count correct " . __LINE__ );

print "wait 5 secs for cache to expire.\n";
sleep(5); 
$c = $obj->get($0);
ok($c, "open file: $0");
is($obj->count(), 1, "store count correct " . __LINE__ );

$obj->configure(expire=>0, max=>1);
is($obj->count(), 1, "store count correct " . __LINE__ );

my $d = $obj->get('Makefile.PL');
ok($d, "open new file 'Makefile.PL'");
is($obj->count(), 1, "store count correct " . __LINE__ );
#print Dumper $obj; exit;

$d = $obj->get('MANIFEST');
ok($d, "open new file 'MANIFEST'");
is($obj->count(), 1, "store count correct " . __LINE__ );

# This should clean the cache because it's set to a max of 1
ok($obj->get('MANIFEST'), "open another file");
ok($obj->get($0), "open another file");
ok($obj->get($0), "open another cached file");

my $e = $obj->get('missing');
ok(!$e, "open non-existant file");

$obj->configure(expire=>0, max=>3);

$obj->get('./lib/File/Store.pm');
for my $f qw(
	t/standalone.t
	t/class.t
	Makefile.PL
	lib/File/Store.pm
	MANIFEST
)
{
	ok($obj->get($f), "open file '$f'");
	#print Dumper $obj->{queue};
}
is($obj->count(), 3, "store count correct " . __LINE__ );


$obj->clear();
is($obj->count(), 0, "store count " . $obj->count() . " correct after clear");


SKIP: {
	eval " use File::Touch; ";

	skip "File::Touch not installed", 2 if $@;

	my $file = 'X';
	touch ($file);

	my $str = $obj->get($file);

	unlink ($file);
	$str = $obj->get($file);

	is($str, undef, "cache removal for vanished file ($!).");
	is($obj->count(), 0, "store count correct " . $obj->count());
}

