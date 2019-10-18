package main;

use strict;
use warnings;

use Test::More 0.88;

use constant HASH_REF	=> ref {};

my $module = 'Geo::WebService::Elevation::USGS';

require_ok($module)
    or BAIL_OUT ("Can not continue without loading $module");

my $ele = eval {$module->new()};
isa_ok($ele, $module)
    or BAIL_OUT ("Can not continue without instantiating $module");

is($ele->get('units'), 'FEET', 'Units default to feet');
$ele->set(units => 'METERS');
is($ele->get('units'), 'METERS', 'Units can be set to meters');
$ele->set(units => 'FEET');
is($ele->get('units'), 'FEET', 'Units can be set back to feet');
ok($ele->get('croak'), 'Croak defaults to true');
$ele->set(croak => undef);
ok(!$ele->get('croak'), 'Croak can be set false');
is($ele->get('proxy'),
    'http://gisdata.usgs.gov/XMLWebServices2/Elevation_Service.asmx',
    'Proxy is as expected');
ok(!defined($ele->get('places')), 'Places defaults to undefined');
$ele->set(places => 2);	# USGS returns insane precision
is($ele->get('places'), 2, 'Places can be set to 2');
my $rslt = eval {$ele->attributes()};
ok($rslt, 'attributes() returned something');
is(ref $rslt, HASH_REF, 'attributes() returned a hash reference');
is($rslt->{places}, 2, 'attributes() returned places => 2');
$rslt->{places} = undef;
is($ele->get('places'), 2,
    'Manipulating attributes() return does not affect attributes');
eval {$ele->set(places => 'fubar')};
like($@, qr{ \A\QAttribute places must be an unsigned integer}smx,
    'Setting places to a non-integer should blow up,');
is($ele->get('places'), 2, 'and not change the value of places');
eval {$ele->set(places => undef)};
ok(!$@, 'Setting places to undef should work');
is($ele->get('places'), undef, 'and yield undef for places');
$ele->set(places => 2);	# For subsequent testing

{
    my %rslt = eval {$ele->attributes()};
    ok(scalar %rslt, 'attributes() returned something in list context');
    is($rslt{places}, 2, 'attributes() returned places => 2');
    my $bogus = eval {Geo::WebService::Elevation::USGS::new()};
    my $msg = $@ || '';
    ok(!$bogus, 'Function call to new() returned nothing');
    like($msg, qr{ \A\QNo class name specified}smx,
	'Function call to new() threw an error');
    $rslt = eval{$ele->get('fubar')};
    like($@, qr{ \A\QNo such attribute as 'fubar'}smx,
	"Can't get attribute 'fubar'");
    $rslt = eval{$ele->set(fubar => 'baz')};
    like($@, qr{ \A\QNo such attribute as 'fubar'}smx,
	"Can't set 'fubar' either");
    $ele->{_bogus} = 'really';
    $rslt = eval{$ele->get('_bogus')};
    like($@, qr{  \A\QNo such attribute as '_bogus'}smx,
	"Can't get attribute '_bogus'");
    $rslt = eval{$ele->set(_bogus => 'baz')};
    like($@, qr{ \A\QNo such attribute as '_bogus'}smx,
	"Can't set '_bogus' either");
    %rslt = eval {$ele->attributes()};
    ok(!exists $rslt{_bogus},
	"'_bogus' should not appear in attributes() output");
}

$rslt = eval {$module->is_valid(0)};
ok(!$@, 'is_valid(0) should succeed');
ok($rslt, 'is_valid(0) should be true');
$rslt = eval {$module->is_valid('bogus')};
ok(!$@, 'is_valid(\'bogus\') should succeed');
ok(!$rslt, 'is_valid(\'bogus\') should be false');
$rslt = eval {$module->is_valid(undef)};
ok(!$@, 'is_valid(undef) should succeed');
ok(!$rslt, 'is_valid(undef) should be false');
$rslt = eval {$module->is_valid(-1e310)};
ok(!$@, 'is_valid(-1e310) should succeed');
ok(!$rslt, 'is_valid(-1e310) should be false');
$rslt = eval {$ele->is_valid({Elevation => 0})};
ok(!$@, 'is_valid({Elevation => 0}) should succeed');
ok($rslt, 'is_valid({Elevation => 0}) should be true');
$rslt = eval {$ele->is_valid([])};
like ($@, qr{ \A\QARRAY reference not understood}smx,
    'is_valid() should croak when passed an array reference');

done_testing;

1;
