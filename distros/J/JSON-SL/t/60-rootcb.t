#!/usr/bin/perl
use strict;
use warnings;
use JSON::SL;
use Test::More;
use Data::Dumper;

my $jsn = JSON::SL->new();
my @root_objs = ();

sub rootcb {
    push @root_objs, $_[0];
}

my $prev_cb;

$prev_cb = $jsn->root_callback( \&rootcb );
is($prev_cb, undef);
$prev_cb = $jsn->root_callback(undef);
is($prev_cb, \&rootcb);

eval {
    $jsn->root_callback("meh");
}; like($@, '/CODE ref/', "Got error on passing non CODE-ref");

is($jsn->root_callback(\&rootcb), undef);


# Now see if the thing actually works

my $txt = '[1], [2], [3], [4]';

$jsn->feed($txt);
is_deeply(\@root_objs, [[1],[2],[3],[4]]);

done_testing();
