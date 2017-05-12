#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use HTML::Escape;
use HTML::Entities;
use Benchmark ':all';
my $txt = "<=> (^^)" x 10000;

cmpthese(
    -1, {
        "HTML::Escape" => sub {
            escape_html($txt);
        },
        "HTML::Entities" => sub {
            encode_entities($txt);
        },
    },
);
