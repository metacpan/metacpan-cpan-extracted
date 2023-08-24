#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;

plan tests => 5;

use HTML::Acronyms ();

{
    my $acro = HTML::Acronyms->new(
        {
            dict => +{
                SQL => {
                    abbr  => "SQL",
                    title => "Structured Query Language",
                    url   => qq#https://en.wikipedia.org/wiki/SQL#,
                },
                WDYM => {
                    abbr  => "WDYM",
                    title => "what do you mean",
                    url   => "https://en.wiktionary.org/wiki/WDYM",
                },
            }
        }
    );

    # TEST
    ok( $acro, "initialized" );

    # TEST
    is(
        scalar( $acro->abbr( { key => 'WDYM', no_link => 1 } )->{html} ),
        qq#<abbr title="what do you mean">WDYM</abbr>#,
        "no_link test",
    );

    # TEST
    is(
        scalar( $acro->abbr( { key => 'SQL', no_link => 0 } )->{html} ),
qq#<a href="https://en.wikipedia.org/wiki/SQL"><abbr title="Structured Query Language">SQL</abbr></a>#,
        "no_link test",
    );

    # TEST
    is(
        scalar( $acro->abbr( { key => 'WDYM', link => 0 } )->{html} ),
        qq#<abbr title="what do you mean">WDYM</abbr>#,
        "false link test",
    );

    # TEST
    is(
        scalar( $acro->abbr( { key => 'SQL', link => 1 } )->{html} ),
qq#<a href="https://en.wikipedia.org/wiki/SQL"><abbr title="Structured Query Language">SQL</abbr></a>#,
        "link test",
    );
}
