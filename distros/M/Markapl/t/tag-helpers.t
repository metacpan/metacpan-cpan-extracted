#!perl

use lib 't/lib';

use strict;
use warnings;
use Test::More tests => 7;

use MyTestView2;

for my $name (qw/heads-cells THs-TDs ths-tds/) {
    my $out = MyTestView2->render("/helper-${name}");

    like($out, qr/<th>(.+)<\/th>/,  "TH helper works" );
    like($out, qr/<td>(.+)<\/td>/,  "TD helper works" );
}

{
    my $out = MyTestView2->render("/helper-linklist");
    like($out, qr/<ul><li><a.+>.+<\/a><\/li>/);
}
