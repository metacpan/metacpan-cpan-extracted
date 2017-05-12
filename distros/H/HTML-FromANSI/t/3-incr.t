#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use ok 'HTML::FromANSI';

my $h = HTML::FromANSI->new(
    cols        => 1, # minimum width
    show_cursor => 1,
);

$h->add_text("\x1b[1;34m", "This text is bold blue.");

is($h->html, join('', split("\n", << '.')), 'basic conversion');
<tt><font
 face='fixedsys, lucida console, terminal, vga, monospace'
 style='line-height: 1; letter-spacing: 0; font-size: 12pt'
><span style='color: blue; background: black; '>
This&nbsp;text&nbsp;is&nbsp;bold&nbsp;blue.</span>
<span style='color: black; background: black; '><br></span>
</font></tt>
.

$h->add_text("\x1b[1;34m", "more of the same");

is($h->html, join('', split("\n", << '.')), 'new text');
<tt><font
 face='fixedsys, lucida console, terminal, vga, monospace'
 style='line-height: 1; letter-spacing: 0; font-size: 12pt'
><span style='color: blue; background: black; '>
This&nbsp;text&nbsp;is&nbsp;bold&nbsp;blue.
more&nbsp;of&nbsp;the&nbsp;same</span>
<span style='color: black; background: black; '><br></span>
</font></tt>
.
