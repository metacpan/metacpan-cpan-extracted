# $Id: descriptor.t,v 1.2 2008-04-01 20:21:37 mike Exp $

use strict;
use Test;
BEGIN { plan tests => 15 };
use Keystone::Resolver::Descriptor;
ok(1); # If we made it this far, we're ok.

my $d = new Keystone::Resolver::Descriptor("test");
ok(defined $d);
ok($d->name(), "test");

my $data = $d->metadata("key");
ok(!defined($data));

$data = $d->superdata("key");
ok(!defined($data));

$d->metadata("key", 1);
$d->superdata("key", 2);
$d->superdata("key2", 3);
ok($d->metadata("key"), 1);
ok($d->superdata("key"), 2);
ok($d->superdata("key2"), 3);

my $val;
eval {
    $val = $d->metadata1("key");
};
ok($@);

ok(join(",", $d->metadata_keys()), "key");
ok(join(",", $d->superdata_keys()), "key,key2");

$d->delete_superdata("key");
ok(join(",", $d->superdata_keys()), "key2");

$d->push_metadata("foo" => "fish");
ok(join(",", $d->metadata_keys()), "foo,key");
ok($d->metadata1("foo"), "fish");

$d->push_metadata("foo" => "frog", "fruit");
ok(join(",", @{ $d->metadata("foo") }), "fish,frog,fruit");
