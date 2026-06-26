use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

my $html = $h->html(
    [
        head => [ title => ["Void Tag Test"] ],
        body => [
            div => [
                hr => {},
                br => {},
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Void Tag Test</title></head><body><div><hr><br></div></body></html>',
  'hr and br render as void elements without closing tags';

$html = $h->html(
    [
        head => [ title => ["Image Test"] ],
        body => [
            figure => [
                img        => { src => "/img/photo.jpg", alt => "A photo" },
                figcaption => ["A photo"],
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Image Test</title></head><body><figure><img alt="A photo" src="/img/photo.jpg"><figcaption>A photo</figcaption></figure></body></html>',
  'img renders as void element with sorted attributes';

$html = $h->html(
    [
        head => [ title => ["Input Test"] ],
        body => [
            form => [
                input =>
                  { type => "text", name => "q", placeholder => "Search..." },
                input => { type => "submit", value => "Go" },
            ]
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Input Test</title></head><body><form><input name="q" placeholder="Search..." type="text"><input type="submit" value="Go"></form></body></html>',
  'input elements render as void with multiple sorted attributes';

$html = $h->html(
    [
        head => [
            meta  => { charset => "UTF-8" },
            title => ["Meta/Link Test"],
            link  => { rel => "stylesheet", href => "/css/style.css" },
        ],
        body => [ p => ["Content"] ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Meta/Link Test</title><link href="/css/style.css" rel="stylesheet"></head><body><p>Content</p></body></html>',
  'meta and link render as void elements in head';

$html = $h->html(
    [
        head => [ title => ["Mixed Test"] ],
        body => [
            p  => ["Before"],
            hr => {},
            p  => ["After"],
        ]
    ]
);

is $html,
'<!DOCTYPE html><html><head><title>Mixed Test</title></head><body><p>Before</p><hr><p>After</p></body></html>',
  'void and non-void tags interleaved at the same level';

done_testing;
