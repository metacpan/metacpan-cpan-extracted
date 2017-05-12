#!/usr/bin/perl
# randfile.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use Directory::Scratch;
eval "use String::Random";
plan skip_all => "Requires String::Random" if $@;
plan tests => 321;

my $tmp = Directory::Scratch->new;
ok($tmp, 'create $tmp');

for(1..80){
    my $name;
    ok($name = $tmp->randfile(60, 100), 'create random file');
    ok(-e $name, 'created ok');
    my @stat = stat _;
    ok($stat[7] <= 100 && $stat[7] >= 60, 'file is the correct size');
    ok(unlink($name), "delete $name");
}
