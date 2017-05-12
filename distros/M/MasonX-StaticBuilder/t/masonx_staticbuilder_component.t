#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing new
{
use_ok('MasonX::StaticBuilder::Component');
my $t = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/test-component"
});
isa_ok($t, 'MasonX::StaticBuilder::Component');

can_ok($t, qw(comp_root comp_name));
like($t->comp_root(), qr!/t$!, "comp_root()");
is($t->comp_name(), "/test-component", "comp_name()");

my $no = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/this/file/does/not/exist",
});
is($no, undef, "new returns undef if the file can't be loaded");
}



# =begin testing fill_in
{
my $t = MasonX::StaticBuilder::Component->new({
    comp_root => "t",
    comp_name => "/test-component"
});
my $out = $t->fill_in( foo => "bar" );
like($out, qr/This is a test/, "template handles simple text");
like($out, qr/42/, "template handles mason directives");
like($out, qr/foo is bar/, "template handles args");
}




1;
