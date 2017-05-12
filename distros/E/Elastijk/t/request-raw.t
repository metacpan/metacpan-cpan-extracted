#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Hijk;

my $wanted_response_body = q<{"ok":true,"hits":{"hits":[],"total":0}}>;
{
    no warnings 'redefine';
    sub Hijk::request {
        return { status => "200", body => $wanted_response_body }
    };
}

use Elastijk;

my ($status, $res_body) = Elastijk::request_raw({ body => q<{"query":{"match_all":{}}}> });

is ref($res_body), '';
is $res_body, $wanted_response_body;

done_testing;
