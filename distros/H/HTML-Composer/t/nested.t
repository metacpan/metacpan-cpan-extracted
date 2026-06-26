use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

my $html = $h->html(
    [
        head => [ title => ["Nested Test"] ],
        body => [
            div => { id => "outer" } => [
                div => { id => "middle" } => [
                    div => { id => "inner" } => [
                        span => ["Deep text"]
                    ]
                ]
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Nested Test</title></head><body><div id="outer"><div id="middle"><div id="inner"><span>Deep text</span></div></div></div></body></html>',
  'deeply nested divs render with correct open/close tag pairing';

$html = $h->html(
    [
        head => [ title => ["Escape Test"] ],
        body => [
            p => ["Hello <World> & Everyone"],
            p => ["Price: 5 > 3"],
        ]
    ]
);

like $html, qr{<p>Hello &lt;World&gt; &amp; Everyone</p>},
  'angle brackets and ampersands in text are HTML-escaped';
like $html, qr{<p>Price: 5 &gt; 3</p>},
  'greater-than sign in text is HTML-escaped';

$html = $h->html(
    [
        head => [ title => ["Attr Escape Test"] ],
        body => [
            a => { href => "/search?a=1&b=2", title => "R&D" } => ["Link"]
        ]
    ]
);

like $html, qr{href="[^"]*&amp;[^"]*"},
  'ampersand in href attribute value is HTML-escaped';
like $html, qr{title="R&amp;D"},
  'ampersand in title attribute value is HTML-escaped';

$html = $h->html(
    [
        head => [
            meta  => { charset => "UTF-8" },
            title => ["Contact Form"],
            link  => { rel => "stylesheet", href => "/css/main.css" },
        ],
        body => [
            h1   => ["Contact Us"],
            form => { action => "/submit", method => "post" } => [
                label => { for  => "name" } => ["Your Name:"],
                input => { type => "text", id => "name", name => "name" },
                label => { for  => "email" } => ["Your Email:"],
                input => { type => "email",  id => "email", name => "email" },
                input => { type => "submit", value => "Send" },
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Contact Form</title><link href="/css/main.css" rel="stylesheet"></head><body><h1>Contact Us</h1><form action="/submit" method="post"><label for="name">Your Name:</label><input id="name" name="name" type="text"><label for="email">Your Email:</label><input id="email" name="email" type="email"><input type="submit" value="Send"></form></body></html>',
  'contact form with labels and inputs renders correctly';

$html = $h->html(
    [
        head => [ title => ["Nav Test"] ],
        body => [
            nav => { id => "main-nav" } => [
                ul => [
                    li => [ a => { href => "/" }        => ["Home"] ],
                    li => [ a => { href => "/about" }   => ["About"] ],
                    li => [ a => { href => "/contact" } => ["Contact"] ],
                ]
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Nav Test</title></head><body><nav id="main-nav"><ul><li><a href="/">Home</a></li><li><a href="/about">About</a></li><li><a href="/contact">Contact</a></li></ul></nav></body></html>',
  'navigation list with anchors renders correctly';

$html = $h->html(
    { lang => "fr" },
    [
        head => [ title => ["Lang Test"] ],
        body => [ p     => ["Bonjour"] ]
    ]
);

is $html,
'<!DOCTYPE html><html lang="fr"><head><title>Lang Test</title></head><body><p>Bonjour</p></body></html>',
  'lang attribute on root html element renders correctly';

$html = $h->html(
    [
        head => [ title => ["Class Test"] ],
        body => [
            div => { class => [ "container", "mx-auto", "p-4" ] } => [
                p => { class => [ "text-lg", "font-bold" ] } => ["Styled text"]
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Class Test</title></head><body><div class="container mx-auto p-4"><p class="text-lg font-bold">Styled text</p></div></body></html>',
  'CSS class arrays are joined with spaces in attribute value';

done_testing;
