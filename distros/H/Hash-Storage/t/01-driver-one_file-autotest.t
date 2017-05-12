#!/usr/bin/perl

use Test::More;
use Hash::Storage;
use Hash::Storage::AutoTester;
use File::Temp qw/tmpnam/;

BEGIN {
    use_ok( 'Hash::Storage' ) || print "Bail out!\n";
}

my $st = Hash::Storage->new( driver => [ OneFile => { file => scalar tmpnam(), serializer => 'JSON' } ] );

my $tester = Hash::Storage::AutoTester->new(storage => $st);
$tester->run();

done_testing;