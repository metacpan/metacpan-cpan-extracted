#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use HTML::Widgets::NavMenu::Url ();

{
    my $from =
        HTML::Widgets::NavMenu::Url->new( [qw(hello there wow.html)], 1, );
    my $to = HTML::Widgets::NavMenu::Url->new( [qw(hello there wow.html)], 0, );

    my $url;
    eval { $url = $from->_get_relative_url($to); };

    # TEST
    like(
        $@,
        qr{^Two identical URLs},
        "Checking that an exception was thrown."
    );
}

{
    my $from = HTML::Widgets::NavMenu::Url->new( [], 0, );
    my $to   = HTML::Widgets::NavMenu::Url->new( [], 0, );

    my $url;
    eval { $url = $from->_get_relative_url($to); };

    # TEST
    like( $@, qr{^Root URL}, "Checking that an exception was thrown." );
}

{
    my $from = HTML::Widgets::NavMenu::Url->new( ["hello"], 1, "harddisk", );
    my $to   = HTML::Widgets::NavMenu::Url->new( ["good.html"], 0, );

    # TEST
    is( $from->_get_relative_url( $to, 1 ),
        "../good.html", "Checking for harddisk URL from dir to file" );
}

{
    my $from = HTML::Widgets::NavMenu::Url->new( ["hello"], 1, "harddisk", );
    my $to   = HTML::Widgets::NavMenu::Url->new( ["good"],  1, );

    # TEST
    is( $from->_get_relative_url( $to, 1 ),
        "../good/index.html", "Checking for harddisk URL from dir to dir" );
}

{
    my $from = HTML::Widgets::NavMenu::Url->new( ["hello"], 1, "harddisk", );
    my $to   = HTML::Widgets::NavMenu::Url->new( ["good"],  1, );

    # TEST
    is( $from->_get_relative_url( $to, 0 ),
        "./good/index.html", "Checking for harddisk URL from dir to dir" );
}

{
    my $from =
        HTML::Widgets::NavMenu::Url->new(
        [ "directory", "sub-dir", "good.html" ],
        0, "server", );
    my $to = HTML::Widgets::NavMenu::Url->new( ["directory"], 1, "server" );

    # TEST
    is( $from->_get_relative_url( $to, 1 ),
        "../", "Checking for relative URL from a non-dir to a dir." );
}

