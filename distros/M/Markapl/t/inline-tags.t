#!/usr/bin/env perl
# {no strict; *{p} = sub { print YAML::Dump(@_) }}

use Markapl;
package MyView;

use Markapl;

sub simple1 {
    p {
        outs "Let's visit my ";
        a(href => "http://example.com") { "Homepage" };
    };
}

sub simple2 {
    p {
        a(href => "http://example.com") { "Homepage" };
        outs " is here.";
    };
}

sub simple3 {
    p {
        outs "My ";
        a(href => "http://example.com") { "Homepage" };
        outs " is here.";
    };
}


package main;
use Test::More;
use Test::HTML::Lint;

plan tests => 12;

{
    my $html = MyView->render("simple1");
    diag $html;

    like($html, qr/<p>.+<\/p>/s);
    like($html, qr/<a.+>.+<\/a>/s);
    html_ok($html);
    is($html, qq{<p>Let's visit my <a href="http://example.com">Homepage</a></p>});
}

{
    my $html = MyView->render("simple2");
    diag $html;

    like($html, qr/<p>.+<\/p>/s);
    like($html, qr/<a.+>.+<\/a>/s);
    html_ok($html);
    is($html, qq{<p><a href="http://example.com">Homepage</a> is here.</p>});
}


{
    my $html = MyView->render("simple3");
    diag $html;

    like($html, qr/<p>.+<\/p>/s);
    like($html, qr/<a.+>.+<\/a>/s);
    html_ok($html);
    is($html, qq{<p>My <a href="http://example.com">Homepage</a> is here.</p>});
}
