#!/usr/bin/perl -w

use Test::More tests => 12;

use strict;

BEGIN
{
    use_ok('HTML::Widgets::NavMenu::TagGen');    # TEST
}

{
    my $test_tag = HTML::Widgets::NavMenu::TagGen->new(
        {
            'name'       => "a",
            'attributes' => {
                'href'  => { 'escape' => 1, },
                'title' => { 'escape' => 0, },
                'id'    => { 'escape' => 1, },
                'iname' => { 'escape' => 0, },
            },
        }
    );

    # TEST
    is(
        $test_tag->gen( { 'href' => "http://www.mysite.com/", } ),
        q{<a href="http://www.mysite.com/">},
        "Simple Tag Test"
    );

    # TEST
    is( $test_tag->gen( { 'href' => "/hello&you<yes>", } ),
        q{<a href="/hello&amp;you&lt;yes&gt;">}, "Escaping" );

    # TEST
    is(
        $test_tag->gen( { 'href' => "http://www.mysite.com/", }, 1 ),
        q{<a href="http://www.mysite.com/" />},
        "Standalone Tag"
    );

    # TEST
    is(
        $test_tag->gen( { 'href' => "/hello&you<yes>", }, 1 ),
        q{<a href="/hello&amp;you&lt;yes&gt;" />},
        "Standalone Tag with Escaping"
    );

    # TEST
    is( $test_tag->gen( {} ), q{<a>}, "Empty Tag" );

    # TEST
    is( $test_tag->gen( {}, 1 ), q{<a />}, "Empty Standalone Tag" );

    # TEST
    is(
        $test_tag->gen( { 'title' => "This is me&amp;yours title" } ),
        q{<a title="This is me&amp;yours title">},
        "Non-escaping for unescaped attribute"
    );

    # TEST
    is(
        $test_tag->gen(
            { 'title' => "Hello", 'href' => "/hi/", 'id' => "myid" }
        ),
        q{<a href="/hi/" id="myid" title="Hello">},
        "Multiple Attributes"
    );

    # TEST
    is(
        $test_tag->gen(
            {
                'title' => "Hello",
                'href'  => "/hi/",
                'id'    => "myid"
            },
            1
        ),
        q{<a href="/hi/" id="myid" title="Hello" />},
        "Multiple Attributes Standalone"
    );
    my $string = "&lt;Hello&amp;";

    # TEST
    is(
        $test_tag->gen( { map { $_ => $string } (qw(href title id iname)) } ),
q{<a href="&amp;lt;Hello&amp;amp;" id="&amp;lt;Hello&amp;amp;" iname="&lt;Hello&amp;" title="&lt;Hello&amp;">},
        "Selective Escaping"
    );

    # TEST
    is(
        $test_tag->gen(
            { map { $_ => $string } (qw(href title id iname)) }, 1
        ),
q{<a href="&amp;lt;Hello&amp;amp;" id="&amp;lt;Hello&amp;amp;" iname="&lt;Hello&amp;" title="&lt;Hello&amp;" />},
        "Selective Escaping Standalone"
    );
}

