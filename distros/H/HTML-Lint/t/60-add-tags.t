#!perl

use warnings;
use strict;

use lib 't/';
use Util;

use HTML::Lint::HTML4;

# This test is the same as t/attr-unknown.t, but with tag table modification.

HTML::Lint::HTML4::add_attribute( 'p', 'food' );
HTML::Lint::HTML4::add_attribute( 'body', 'cuisine' );

HTML::Lint::HTML4::add_tag( 'meal' );
HTML::Lint::HTML4::add_attribute( 'meal', 'type' );

checkit( [
    [ 'attr-unknown' => qr/Unknown attribute "Yummy" for tag <I>/i ],
], [<DATA>] );

__DATA__
<HTML>
    <HEAD>
        <TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white" cuisine="Mexican">
        <P FOOD="Burrito" ALIGN=RIGHT>This is my paragraph about burritos</P>
        <I YUMMY="Spanish Rice">This is my paragraph about refried beans</I>
        <meal type="lunch">Steak burrito</meal>
    </BODY>
</HTML>
