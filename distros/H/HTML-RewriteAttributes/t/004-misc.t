#!/usr/bin/env perl
use strict;
use warnings;
use HTML::RewriteAttributes;
use Test::More tests => 2;

# make sure returning undef deletes the attribute {{{
my $html = << "END";
<html>
    <body>
        <img src="moose.jpg" />
        <img src="http://example.com/nethack.png">
        <p align="justified" style="color: red">
            hooray
        </p>
    </body>
</html>
END

my @seen;

my $rewrote = HTML::RewriteAttributes->rewrite($html, sub {
    my ($tag, $attr, $value) = @_;
    push @seen, [$tag, $attr, $value];
    return if $attr =~ /s/;
    $value;
});

is_deeply(\@seen, [
    [img => src => "moose.jpg"],
    [img => src => "http://example.com/nethack.png"],
    [p => align => "justified"],
    [p => style => "color: red"],
]);

is($rewrote, << "END", "rewrote the html correctly");
<html>
    <body>
        <img />
        <img>
        <p align="justified">
            hooray
        </p>
    </body>
</html>
END
# }}}

