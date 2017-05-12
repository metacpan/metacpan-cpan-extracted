#!/usr/bin/env perl
use strict;
use warnings;
use HTML::RewriteAttributes::Resources;
use Test::More tests => 3;

my $html = << 'END';
<html>
    <head>
        <link type="text/css" href="foo.css" />
        <link type="text/css" href="print.css" media="print" />
    </head>
    <body>
        <img src="moose.jpg" />
        <img src="http://example.com/nethack.png">
        <a href="Example.html">Example</a>
        <p align="justified" style="color: red">
            hooray
        </p>
    </body>
</html>
END

my @seen;
my @seen_inline;

my $rewrote = HTML::RewriteAttributes::Resources->rewrite($html, sub {
    my $uri  = shift;
    my %args = @_;

    push @seen, [$uri, $args{tag}, $args{attr}];

    return uc $uri;
}, inline_css => sub {
    my $uri = shift;

    push @seen_inline, $uri;

    "INLINED CSS";
});

is_deeply(\@seen, [
    ["moose.jpg" => img => "src"],
    ["http://example.com/nethack.png" => img => "src"],
]);

is_deeply(\@seen_inline, [
    "foo.css",
    "print.css",
]);

is($rewrote, << "END", "rewrote the html correctly");
<html>
    <head>
        
<style type="text/css">
<!--

/* foo.css */
INLINED CSS
-->
</style>

        
<style type="text/css" media="print">
<!--

/* print.css */
INLINED CSS
-->
</style>

    </head>
    <body>
        <img src="MOOSE.JPG" />
        <img src="HTTP://EXAMPLE.COM/NETHACK.PNG">
        <a href="Example.html">Example</a>
        <p align="justified" style="color: red">
            hooray
        </p>
    </body>
</html>
END

