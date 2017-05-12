#!/usr/bin/perl -w
use strict;

use Test::More tests => 16;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use File::Path;
use File::Slurp;
use Cache::FileCache;

use lib "../lib";

use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }




my $dirCache = "data/cache/test";
my $file = "data/cache/random_data_file.txt";
END { unlink($file); };

rmtree($dirCache); ok(! -d $dirCache, "Cache dir gone");
mkpath($dirCache); ok(  -d $dirCache, "Cache dir created");
END { rmtree($dirCache); };




my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Lawn.pm";
my $oLocation;
my $rexFile = qr/Game.Location.pm$/;



print "\nPerlySense objects\n";
ok(my $oPsCache = Devel::PerlySense->new(), "new ok");
ok(my $oCache = Cache::FileCache->new({cache_root => $dirCache}), "Cache::FileCache->new ok");
ok($oPsCache->oCache($oCache), "Set oCache");


ok(my $oPsNoCache = Devel::PerlySense->new(), "new ok");



print "\nSmart goto\n";
ok(my $oLocationNoCache = $oPsNoCache->oLocationSmartGoTo(file => $fileOrigin, row => 391, col => 53), "NoCache Found source ok, on method");
ok(my $oLocationCache = $oPsCache->oLocationSmartGoTo(file => $fileOrigin, row => 391, col => 53), "Cache Found source ok, on method");

is($oLocationNoCache->file, $oLocationCache->file, " row ok");
is($oLocationNoCache->row, $oLocationCache->row, " row ok");
is($oLocationNoCache->col, $oLocationCache->col, " row ok");


print "\nTry again with populated cache\n";
ok($oLocationCache = $oPsCache->oLocationSmartGoTo(file => $fileOrigin, row => 391, col => 53), "Cache Found source ok, on method");

is($oLocationNoCache->file, $oLocationCache->file, " row ok");
is($oLocationNoCache->row, $oLocationCache->row, " row ok");
is($oLocationNoCache->col, $oLocationCache->col, " row ok");





__END__
