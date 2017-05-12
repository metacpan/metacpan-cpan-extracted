#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Markapl::FromHTML;

my $html = "<html><h1>Hello World</h1></html>";

my $h2m = Markapl::FromHTML->new;

$h2m->load($html);

is($h2m->dump, <<OUT);
sub {
    html {
        h1 { "Hello World" };
    };
}
OUT

