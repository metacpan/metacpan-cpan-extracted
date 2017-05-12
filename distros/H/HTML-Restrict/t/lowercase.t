#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use HTML::Restrict;

my $html
    = q[<!doctype html><!-- comments go here --><body onLoad="stuff">foo</body>];

like(
    exception {
        my $hr = HTML::Restrict->new( rules => { Body => ['onload'] } );
    },
    qr{tag names must be lower cased},
    "dies on mixed case tag names",
);

like(
    exception {
        my $hr = HTML::Restrict->new( rules => { body => ['onLoad'] } );
    },
    qr{attribute names must be lower cased},
    "dies on mixed case attributes",
);

done_testing();
