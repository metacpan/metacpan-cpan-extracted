#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 1;
use KelpX::AppBuilder 'Base';

sub maps {
    {
        '/' => 'main::Controller::Root',
    }
}

ok __PACKAGE__->can('build'), 'Generated build method for us';
