#!/usr/bin/perl -w
use strict;

use Test::More tests => 7;
use Test::Exception;

use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");





my $fragment = 'Game::Location->new';
my $module = "Game::Location";
my $method = "new";
is(scalar($oDocument->moduleMethodCallAt(row => 158, col => 57)), $fragment, "static new found in scalar context");
is_deeply([$oDocument->moduleMethodCallAt(row => 158, col => 57)], [$module, $method], "static new found in list context");


$fragment = 'Game::Object::Worm->loadFile';
is(scalar($oDocument->moduleMethodCallAt(row => 162, col => 37)), $fragment, "static method found");






__END__
