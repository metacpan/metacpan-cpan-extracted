#!/usr/bin/perl -w
use strict;

use Test::More tests => 23;
use Test::Exception;

use Data::Dumper;

use lib "lib";

use_ok("Devel::PerlySense::Document::Api");
use_ok("Devel::PerlySense::Document::Api::Method");
use_ok("Devel::PerlySense");


my $dirData = "t/data/overview/api/lib";
my $fileOrigin = "$dirData/Game/Object/Worm.pm";


print "\n* Class\n";

ok(my $oDocument = Devel::PerlySense::Document->new(oPerlySense => Devel::PerlySense->new()), "new ok");
ok($oDocument->parse(file => $fileOrigin), "Parsed file ok");


my $oMethod;
my $method = "undeclaredMethod";

ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "new with missing method ok");
is($oMethod->name, $method, "  name set ok");
is($oMethod->oLocationDocumented, undef, "  oLocationDocumented unknown ok");



$method = "isRealPlayer";
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "new with existing method ok");
is($oMethod->name, $method, "  name set ok");
isnt($oMethod->oLocationDocumented, undef, "  oLocationDocumented set ok");
is($oMethod->oLocationDocumented->row, 69, "  oLocationDocumented row correct");





note("Rendering of method signature");


$method = "isRealPlayer";
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "Found method ($method)");
is($oMethod->signature, "isRealPlayer", "  Bareword method name");


$method = "oDirection";
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "Found method ($method)");
is($oMethod->signature, 'oDirection($direction)', "  Method name and  params");



$method = "oEventMove";
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "Found method ($method)");
is($oMethod->signature, 'oEventMove', '  Method name with prefix $self-> or whatever');



$method = "score";
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "Found method ($method)");
is($oMethod->signature, 'score( ... args ... )', '  Method name with tailing ;');





note("Rendering of calling method signature");

$method = "score";
my $oLocation = Devel::PerlySense::Document::Location->new();
$oLocation->file($fileOrigin);
ok($oMethod = Devel::PerlySense::Document::Api::Method->new(
    oDocument => $oDocument,
    name => $method,
), "Found method ($method)");
is($oMethod->signatureCall($oLocation), '->score( ... args ... )', '  Call signature for method in current class');




$oLocation->file("$fileOrigin.another-file");
is($oMethod->signatureCall($oLocation), '\>score( ... args ... )', '  Call signature for method in other class');






__END__
