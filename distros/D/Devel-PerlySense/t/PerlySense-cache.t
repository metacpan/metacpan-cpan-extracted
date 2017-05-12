#!/usr/bin/perl -w
use strict;

use Test::More tests => 17;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use File::Path;
use File::Slurp;
use Cache::FileCache;

use lib "../lib";

use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }


ok(my $oPs = Devel::PerlySense->new(), "new ok");


my $dirData = "data/cache/test";
my $file = "data/cache/random_data_file.txt";
END { unlink($file); };

rmtree($dirData); ok(! -d $dirData, "Cache dir gone");
mkpath($dirData); ok(  -d $dirData, "Cache dir created");
END { rmtree($dirData); };

ok(write_file($file, "whatever"), "Create test file");
ok(-f $file, " Yep, there");



print "\n* No cache active\n";

my $rValue = \"Some text";
my $rGotten;

ok( ! $oPs->cacheSet(file => $file, key => "test", value => $rValue), "Could not set value to emtpy cache");
is($oPs->cacheGet(file => $file, key => "test"), undef, "Could not get value from emtpy cache");



print "\n* Cache active\n";

ok(my $oCache = Cache::FileCache->new({cache_root => $dirData}), "Cache::FileCache->new ok");
ok($oPs->oCache($oCache), "Set oCache");


throws_ok(sub { $oPs->cacheSet(file => "$file/missing.lost", key => "test", value => $rValue) }, qr/read timestamp/, "Set died ok on missing file");
throws_ok(sub { $oPs->cacheGet(file => "$file/missing.lost", key => "test") }, qr/read timestamp/, "Get died ok on missing file");



ok($oPs->cacheSet(file => $file, key => "test", value => $rValue), "Could set value to cache");
ok($rGotten = $oPs->cacheGet(file => $file, key => "test"), "Could get value from cache");
is($$rGotten, $$rValue, "  got back same value");



print "\nExpire file\n";
sleep(1);
ok(write_file($file, "whatever"), "Create test file");
sleep(1);
ok( ! $oPs->cacheGet(file => $file, key => "test"), "Could not get value from file with new timestamp");







__END__
