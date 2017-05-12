#!/usr/bin/perl

use Test::More;
use Hash::Storage;
use Hash::Storage::AutoTester;
use File::Temp;

BEGIN {
    use_ok( 'Hash::Storage' ) || print "Bail out!\n";
}

my $tmp_dir = File::Temp->newdir();
my $st = Hash::Storage->new( driver => [ Files => { dir => $tmp_dir, serializer => 'JSON' } ] );

my $tester = Hash::Storage::AutoTester->new(storage => $st);
$tester->run();

done_testing;