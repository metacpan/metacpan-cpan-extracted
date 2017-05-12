#!/usr/bin/env perl
use strict;
use warnings;
use HTML::RewriteAttributes::Resources;
use Test::More tests => 4;

my $html = << 'END';
<html>
    <head>
        <link type="text/css" href="/comment.css" />
    </head>
    <body>
    </body>
</html>
END

my %css = (
    "/foo.css" => 'SHOULD NOT BE IMPORTED!',
    "/bar.css" => 'bar;',
    "/comment.css" => << 'COMMENT',
begin;
// @import "foo.css";
/*
    from: @import "foo.css";
*/
@import "bar.css";
/*
    from: @import "foo.css";
*/
end;
COMMENT
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
}, inline_imports => 1);

is(@seen, 0, "no ordinary resources seen");
is_deeply(\@seen_css, [
    "/comment.css",
    "/bar.css",
]);

$rewrote =~ s/ +$//mg;
$rewrote =~ s/^ +//mg;

unlike($rewrote, qr/SHOULD NOT BE IMPORTED!/, 'we did not import foo.css since it is only imported in comments');

is($rewrote, << 'END', "rewrote the html correctly");
<html>
<head>

<style type="text/css">
<!--

/* /comment.css */
begin;
// @import "foo.css";
/*
from: @import "foo.css";
*/

/* /bar.css */
bar;
/*
from: @import "foo.css";
*/
end;

-->
</style>

</head>
<body>
</body>
</html>
END
