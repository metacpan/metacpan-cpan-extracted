#!/usr/bin/perl

use Test::More;
use Hash::Storage;
use Hash::Storage::AutoTester;

BEGIN {
    use_ok( 'Hash::Storage' ) || print "Bail out!\n";
}

my $st = Hash::Storage->new( driver => [ Memory => { serializer => 'Dummy' } ] );

my $tester = Hash::Storage::AutoTester->new(storage => $st);
$tester->run();

done_testing;