#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;

package View;
use Markapl;

template one => sub {
    my $thing = span { "Thing" };

    div {
        $thing;
    }
};

template two => sub {
    my $thing = em { "stuff" };

    p {
        "This ", $thing, " is good";
    }
};


package main;

{
    my $out = View->render("one");
    # diag($out);
    is $out, "<div><span>Thing</span></div>";
}

{
    my $out = View->render("two");
    # diag($out);
    is $out, "<p>This <em>stuff</em> is good</p>";
}
