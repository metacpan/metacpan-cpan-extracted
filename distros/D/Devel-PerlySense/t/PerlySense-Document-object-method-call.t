#!/usr/bin/perl -w
use strict;

use Test::More tests => 15;
use Test::Exception;

use File::Basename;
use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense::Document::Location");


BEGIN { -d "t" and chdir("t"); }


ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Lawn.pm";

ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");





my $fragment;

$fragment = '$oObject->oLawn';
is($oDocument->methodCallAt(row => 219, col => 17) . "", $fragment, "Correct perl fragment ok, on method");

my ($object, $method, $oLocationSub);
my (@aMethod);

ok(($object, $method, $oLocationSub) = $oDocument->aObjectMethodCallAt(row => 219, col => 17), "aObjectMethodCallAt ok");
is("$object", '$oObject', "  got oObject");
is("$method", 'oLawn', "  got method");
like($oLocationSub->rhProperty->{source}, qr/sub placeObjectAt.*?displayObjectAt/s, "  got node sub");


is_deeply(
          [ @aMethod = $oDocument->aMethodCallOf(nameObject => $object, oLocationWithin => $oLocationSub) ],
          [qw/ oLawn raBodyLocation /],
          "Found the correct method calls in the sub");


ok(($object, $method, $oLocationSub) = $oDocument->aObjectMethodCallAt(row => 572, col => 16), "aObjectMethodCallAt ok");
is("$object", '$oObject', "  got oObject");
is("$method", 'oLawn', "  got method");
like($oLocationSub->rhProperty->{source}, qr/END.*?oLawn/s, "  got node sub");


is_deeply(
          [ @aMethod = $oDocument->aMethodCallOf(nameObject => $object, oLocationWithin => $oLocationSub) ],
          [qw/ oLawn /],
          "Found the correct method calls in the sub");







__END__
