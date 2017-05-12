#!/usr/bin/perl
use strict;
use warnings;
use JSON::SL;
use utf8;
use Test::More;

my $sl = JSON::SL->new();

my $txt = <<'EOT';
{
"ערך":"כתבה"
}
EOT

my $res = $sl->feed($txt);

ok($res, "Have result");
ok(exists $res->{"ערך"}, "have utf8 key");
is($res->{"ערך"}, "כתבה", "have utf8 value");

# Test RT 100564



$sl = JSON::SL->new;
# $p->utf8(1);
$sl->noqstr(1);
$sl->nopath(1);
$sl->set_jsonpointer(['/^']);

$txt = <<JSON;
[{"id": "hello"}]
JSON

$sl->feed($txt);
my $obj = $sl->fetch;
my %val = %{$obj->{Value}};
foreach my $k (sort keys %val) {
    ok(exists $val{$k});
}
ok(exists $val{id});
is(1, scalar keys %val);

# Ensure this actually _is_ the same value
$val{id} = "World";
is(1, scalar keys %val);
is("World", $val{id});
done_testing();
