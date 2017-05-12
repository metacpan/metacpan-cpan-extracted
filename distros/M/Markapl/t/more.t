#!/usr/bin/env perl
# {no strict; *{p} = sub { print YAML::Dump(@_) }}

use Markapl;
package MyView;

use Markapl;

sub simple {
    h1 { "Hi" };
    div(".entry") {
        p { "Hi there" };
        p { "I am writing some random test" };
        # p { "Let's visit my ", a(href => "http://example.com") { "Homepage" } };
    };

}

no Markapl;
package main;
use Test::More;
use Test::HTML::Lint;

plan tests => 4;

my $html = MyView->render("simple");

print $html, "\n";

like($html, qr/<h1>.+<\/h1>/s);
like($html, qr/<p>.+<\/p>/s);
like($html, qr/<div class="entry">.+<\/div>/s);

html_ok($html);
