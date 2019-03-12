#!/usr/bin/perl -w

use Test::More tests => 9;

use strict;

BEGIN
{
    use_ok('HTML::Widgets::NavMenu::EscapeHtml');    # TEST
}

{
    # TEST
    is( escape_html("hello"), "hello", "Simple 1" );

    # TEST
    is( escape_html("hi\nYou  rule."), "hi\nYou  rule.", "Simple 2 with WS" );

    # TEST
    is( escape_html("D&D"), "D&amp;D", "Ampersand" );

    # TEST
    is( escape_html("<b>Hello</b>"), "&lt;b&gt;Hello&lt;/b&gt;", "Tags" );

    # TEST
    is( escape_html("&amp;"), "&amp;amp;", "Double amp" );

    # TEST
    is( escape_html("&<hello>"), "&amp;&lt;hello&gt;", "Seq of 2" );

    # TEST
    is( escape_html(q{Hi "phony"}), q{Hi &quot;phony&quot;}, "Double quotes" );

    # TEST
    is( escape_html(q{"<&>"}), q{&quot;&lt;&amp;&gt;&quot;}, "All in one" );
}

