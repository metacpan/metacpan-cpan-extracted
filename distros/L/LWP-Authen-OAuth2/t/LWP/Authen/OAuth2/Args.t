#! /usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";

BEGIN {
    use_ok("LWP::Authen::OAuth2::Args", qw(copy_option assert_options_empty));
}

my $obj = bless {};
my $opt = {};

$obj->copy_option($opt, "foo", "bar");
is_deeply($obj, {foo => "bar"}, "Can copy an empty option with default");

$obj->copy_option($opt, "foo", "baz");
is_deeply($obj, {foo => "bar"}, "Silently do not apply default second time");

$opt->{foo} = "baz";
eval {
   $obj->copy_option($opt, "foo");
};
like($@, qr/Refusing.*'foo'/, "Cannot copy over option");

delete $obj->{foo};
$obj->copy_option($opt, "foo");
is_deeply($obj, {foo => "baz"}, "Do copy if the option is missing");
is_deeply($opt, {}, "Do modify opt on copy");

$obj->assert_options_empty($opt);
ok(1, "Did not die asserting empty options empty");
$opt->{bar} = "blat";
eval {
    $obj->assert_options_empty($opt);
};

like($@, qr/Unexpected parameter.*'bar'/, "Catch unexpected parameters");

$obj->copy_option($opt, "bar");
is_deeply($obj, {foo => "baz", bar => "blat"}, "Can copy required");
is_deeply($opt, {}, "Modify opt when copying required");

eval {
    $obj->copy_option($opt, "baz");
};
like($@, qr/'baz' is required.*missing/, "Notice missing required");

$opt->{baz} = undef;
eval {
    $obj->copy_option($opt, "baz");
};
like($@, qr/'baz' is required.*undef/, "Notice undef required");

done_testing();
