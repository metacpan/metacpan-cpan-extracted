#!/usr/bin/perl -w
use strict;

use Test::More tests => 8;
use Test::Exception;


use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");


is_deeply([ sort $oDocument->aNameBase ],
          [ sort qw/
                    Game::Object
                    / ], "Found base modules ok");


ok(! $oDocument->hasBaseClass("Foo::Bar"), "Bogus class not base class");
ok(! $oDocument->hasBaseClass("Game::Object::Worm"), "Current class not base class");
ok(  $oDocument->hasBaseClass("Game::Object"), "Actual base class identified");



__END__
