use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

my $html = $h->html(
    [
        head => [
            title  => ["My Site"],
            script => {
                src  => "/js/myScript.js",
                type => "text/javascript"
            }
        ],
        body => [
            h1  => ["Hello World!"],
            div => { class => [ "p-3", "background-red" ] } => [
                "Hello World!", h2 => ["Test 123"]
            ]
        ]
    ]
);

ok $html, 'HTML is non undef';
is $html,
'<!DOCTYPE html><html><head><title>My Site</title><script src="/js/myScript.js" type="text/javascript"></script></head><body><h1>Hello World!</h1><div class="p-3 background-red">Hello World!<h2>Test 123</h2></div></body></html>',
  'HTML rendered properly';

$html = $h->html(
    { lang => 'en' },
    [
        head => [
            title  => ["My Site"],
            script => {
                src  => "/js/myScript.js",
                type => "text/javascript"
            }
        ],
        body => [
            h1  => ["Hello World!"],
            div => { class => [ "p-3", "background-red" ] } => [
                "Hello World!",
                h2 => { class => 'background-blue' } => ["Test 123"]
            ]
        ]
    ]
);

ok $html, 'HTML is non undef';
is $html,
'<!DOCTYPE html><html lang="en"><head><title>My Site</title><script src="/js/myScript.js" type="text/javascript"></script></head><body><h1>Hello World!</h1><div class="p-3 background-red">Hello World!<h2 class="background-blue">Test 123</h2></div></body></html>',
  'HTML rendered properly';

done_testing;
