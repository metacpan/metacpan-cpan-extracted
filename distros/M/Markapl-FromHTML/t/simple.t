#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Markapl::FromHTML;

my $html = <<HTML;
<h1>Hello World</h1>
<p>I am very good</p>
<div><p>I am very good, too</p></div>
HTML

my $h2m = Markapl::FromHTML->new;

$h2m->load($html);

is($h2m->dump, <<MARKAPL);
sub {
    h1 { "Hello World" };
    p { "I am very good" };
    div {
        p { "I am very good, too" };
    };
}
MARKAPL

