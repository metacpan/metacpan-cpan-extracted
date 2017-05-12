#!/usr/bin/perl -w
use strict;

use Test::More tests => 5;
use Test::Exception;


use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

is_deeply([ sort $oDocument->aNameModuleUse() ],
          [ sort qw/
                    Data::Dumper
                    Game::Location
                    Game::Direction
                    Game::Event::Timed
                    Exception::Class
                    Class::MethodMaker
                    / ], "Found used modules ok");




__END__
