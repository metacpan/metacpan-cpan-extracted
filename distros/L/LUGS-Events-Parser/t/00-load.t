#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN
{
    my @modules = (
        'LUGS::Events::Parser',
        'LUGS::Events::Parser::Event',
        'LUGS::Events::Parser::Filter',
    );
    use_ok($_) foreach @modules;
}
