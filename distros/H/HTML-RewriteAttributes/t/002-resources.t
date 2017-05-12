#!/usr/bin/env perl
use strict;
use warnings;
use HTML::RewriteAttributes::Resources;
use Test::More tests => 2;

my $html = << "END";
<html>
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

my $rewrote = HTML::RewriteAttributes::Resources->rewrite($html, sub {
    my $uri  = shift;
    my %args = @_;

    push @seen, [$uri, $args{tag}, $args{attr}];

    return reverse $uri;
});

is_deeply(\@seen, [
    ["moose.jpg" => img => "src"],
    ["http://example.com/nethack.png" => img => "src"],
]);

is($rewrote, << "END", "rewrote the html correctly");
<html>
    <body>
        <img src="gpj.esoom" />
        <img src="gnp.kcahten/moc.elpmaxe//:ptth">
        <a href="Example.html">Example</a>
        <p align="justified" style="color: red">
            hooray
        </p>
    </body>
</html>
END

