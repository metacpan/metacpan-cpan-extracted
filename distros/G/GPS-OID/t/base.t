# -*- perl -*-
use Test::More tests => 21;
BEGIN { use_ok( 'GPS::OID' ); }

my $obj = GPS::OID->new();
isa_ok($obj, "GPS::OID");

is($obj->prn_oid(22231), "01", "prn_oid");
is($obj->prn_oid("22231"), "01", "prn_oid");
is($obj->oid_prn(1), 22231, "oid_prn");
is($obj->oid_prn("1"), 22231, "oid_prn");
is($obj->oid_prn("01"), 22231, "oid_prn");
is($obj->oid_prn(1), "22231", "oid_prn");
is($obj->prn_oid(22231), "01", "prn_oid");

is($obj->prn_oid(29486), 31, "prn_oid");
is($obj->oid_prn(31), 29486, "oid_prn");

is($obj->overload(12345, 123), "added", "overload");
is($obj->prn_oid(12345), 123, "prn_oid");
is($obj->oid_prn(123), 12345, "oid_prn");

is($obj->overload(22231, 222), "overloaded", "overload");
is($obj->prn_oid(22231), 222, "prn_oid");
is($obj->oid_prn(222), 22231, "oid_prn");
$obj->reset;
is($obj->prn_oid(22231), "01", "prn_oid");

#ok($obj->overload(22222=>undef()), undef());

my $list=$obj->listprn;
isa_ok($list, "ARRAY", "listprn");

$list=$obj->listoid;
isa_ok($list, "ARRAY", "listoid");

my @listprn=$obj->listprn;
my @listoid=$obj->listoid;
is(scalar(@listprn), scalar(@listoid), "sizes");
