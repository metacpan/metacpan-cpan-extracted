#!/usr/bin/perl -w
use strict;

use Test::More tests => 6;
use Test::Exception;

use Data::Dumper;
use File::Basename;
use File::Spec::Functions;

use lib "../lib";

use_ok("Devel::PerlySense");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Meta");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");


my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

my $oMeta = $oDocument->oMeta;

is_deeply([sort @{$oMeta->raNameModuleUse}], [
    sort qw/
       Class::MethodMaker
       Data::Dumper
       Exception::Class
       Game::Direction
       Game::Event::Timed
       Game::Location
       /], " correct used modules");

#print Dumper($oMeta);



__END__
