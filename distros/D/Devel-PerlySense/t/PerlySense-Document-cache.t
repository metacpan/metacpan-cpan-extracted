#!/usr/bin/perl -w
use strict;

use Test::More tests => 20;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;
use File::Path;
use File::Slurp;
use Cache::FileCache;

use lib "../lib";

use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }



ok(my $oPs = Devel::PerlySense->new(), "new ok");


my $dirData = "data/cache/test";

rmtree($dirData); ok(! -d $dirData, "Cache dir gone");
mkpath($dirData); ok(  -d $dirData, "Cache dir created");
END { rmtree($dirData); };



ok(my $oCache = Cache::FileCache->new({cache_root => $dirData}), "Cache::FileCache->new ok");
is($oCache->size, 0, " Cache is empty");
ok($oPs->oCache($oCache), "Set oCache");


my $dirSource = "data/project-lib";
my $fileOrigin = "$dirSource/Game/Object/Worm/ShaiHulud.pm";

my $fragment = 'Game::Location->new';
my $module = "Game::Location";
my $method = "new";


ok(my $oDocumentWithout = Devel::PerlySense::Document->new(oPerlySense => $oPs), "new ok");
ok($oDocumentWithout->parse(file => $fileOrigin), "Parsed file ok");

ok(my $size = $oCache->size," Cache has contents");

print "Check that somehting known works\n";
#is(scalar($oDocumentWithout->moduleMethodCallAt(row => 158, col => 57)), $fragment, "static new found in scalar context");
#is_deeply([$oDocumentWithout->moduleMethodCallAt(row => 158, col => 57)], [$module, $method], "static new found in list context");

ok(eq_set([ $oDocumentWithout->aNameBase() ], ["Game::Object::Worm", "Game::Lawn"]), 'Two base classes (@ISA = ...) ok');





ok(my $oPsWith = Devel::PerlySense->new(), "new ok");
ok(my $oCacheWith = Cache::FileCache->new({cache_root => $dirData}), "Cache::FileCache->new ok");
ok($oPsWith->oCache($oCacheWith), " Set oCache ok");

ok(my $oDocumentWith = Devel::PerlySense::Document->new(oPerlySense => $oPsWith), "new ok");
ok($oDocumentWith->parse(file => $fileOrigin), "Parsed file ok");

is($oCacheWith->size, $size, " Cache has same contents");

print "Check that somehting known works with caching\n";
#is(scalar($oDocumentWith->moduleMethodCallAt(row => 158, col => 57)), $fragment, "static new found in scalar context");
#is_deeply([$oDocumentWith->moduleMethodCallAt(row => 158, col => 57)], [$module, $method], "static new found in list context");

ok(eq_set([ $oDocumentWith->aNameBase() ], ["Game::Object::Worm", "Game::Lawn"]), 'Two base classes (@ISA = ...) ok');




print "Compare with/without\n";

my $countWithout = 0;
my $sourceWithout = "";
$oDocumentWithout->aDocumentFind(sub { $sourceWithout .= "<<$_[1]>>"; $countWithout++; 0; } );

my $countWith = 0;
my $sourceWith = "";
$oDocumentWith->aDocumentFind(sub { $sourceWith .= "<<$_[1]>>"; $countWith++; 0; } );

is($countWithout, $countWith, " oDocument nodes same count");
is($sourceWithout, $sourceWith, " oDocument nodes same source");
#print "$sourceWith\n";






__END__
