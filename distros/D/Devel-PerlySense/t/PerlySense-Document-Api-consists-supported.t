#!/usr/bin/perl -w
use strict;

use Test::More tests => 18;
use Test::Exception;

use Data::Dumper;

use lib "../lib";

use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document");
use_ok("Devel::PerlySense");


BEGIN { -d "t" and chdir("t"); }

my $dirData = "data/project-lib";
my $fileOrigin = "$dirData/Game/Event/Timed.pm";
my $nameModule = "Game::Event::Timed";

my $oLocation;
my $method;


print "\n* Class\n";

ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");

ok($oDocument->determineLikelyApi(nameModule => $nameModule), "determineLikelyApi ok");

ok(my $oApi = $oDocument->rhPackageApiLikely->{$nameModule}, "Got package API ok");




my $raMethod;


$raMethod = [qw/ timeNextTick timeInterval checkTick /];
is($oApi->percentSupportedOf($raMethod), 100, " percentSupportedOf for all present");

$raMethod = [qw/ missing_method /];
is($oApi->percentSupportedOf($raMethod), 0, " percentSupportedOf for none present");

$raMethod = [qw/  /];
is($oApi->percentSupportedOf($raMethod), 0, " percentSupportedOf for none given (and none present)");

$raMethod = [qw/ timeNextTick timeInterval checkTick missing_method /];
is($oApi->percentSupportedOf($raMethod), 75, " percentSupportedOf for one missing present");





$raMethod = [qw/ missing_method /];
is($oApi->percentConsistsOf($raMethod), 0, " percentConsistsOf for one missing method");

$raMethod = [qw/  /];
is($oApi->percentConsistsOf($raMethod), 0, " percentConsistsOf for no methods");

$raMethod = [qw/ missing_method /];
is($oApi->percentConsistsOf($raMethod), 0, " percentConsistsOf for one missing method");

$raMethod = [qw/ timeNextTick timeInterval new checkTick  /];
is($oApi->percentConsistsOf($raMethod), 100, " percentConsistsOf for all methods");

$raMethod = [qw/ timeNextTick timeInterval new checkTick missing_method /];
is($oApi->percentConsistsOf($raMethod), 100, " percentConsistsOf for all methods + one extra");

$raMethod = [qw/ timeNextTick timeInterval new /];
is($oApi->percentConsistsOf($raMethod), 75, " percentConsistsOf for all methods but one");


$raMethod = [qw/ timeNextTick timeInterval new missing_method /];
is($oApi->percentConsistsOf($raMethod), 75, " percentConsistsOf for all methods but one + one extra");


  


__END__
