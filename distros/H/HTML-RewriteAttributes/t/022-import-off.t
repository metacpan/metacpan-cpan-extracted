#!/usr/bin/env perl
use strict;
use warnings;
use HTML::RewriteAttributes::Resources;
use Test::More tests => 3;

my $html = << 'END';
<html>
    <head>
        <link type="text/css" href="foo.css" />
        <style type="text/css">
@import "bar.css";
        </style>
        <link type="text/css" href="baz.css" />
    </head>
    <body>
    </body>
</html>
END

my %css = (
    "foo.css"  => 'foo; @import "quux.css";',
    "bar.css"  => 'bar; @import "quux.css";',
    "baz.css"  => 'baz; @import "foo.css";',
    "quux.css" => 'quux; @import "bar.css"; @import "quux.css";',
);

my @seen;
my @seen_css;

my $rewrote = HTML::RewriteAttributes::Resources->rewrite($html, sub {
    my $uri = shift;
    push @seen, $uri;
    return $uri;
}, inline_css => sub {
    my $uri = shift;
    push @seen_css, $uri;
    return $css{$uri};
});

is(@seen, 0, "no ordinary resources seen");
is_deeply(\@seen_css, [
    "foo.css",
    "baz.css",
]);

$rewrote =~ s/ +$//mg;
$rewrote =~ s/^ +//mg;

is($rewrote, << 'END', "rewrote the html correctly");
<html>
<head>

<style type="text/css">
<!--

/* foo.css */
foo; @import "quux.css";
-->
</style>

<style type="text/css">
@import "bar.css";
</style>

<style type="text/css">
<!--

/* baz.css */
baz; @import "foo.css";
-->
</style>

</head>
<body>
</body>
</html>
END

