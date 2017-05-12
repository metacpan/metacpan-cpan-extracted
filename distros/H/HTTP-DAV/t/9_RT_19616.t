#!/usr/bin/env perl

use strict;
use Test::More (tests => 2);

use_ok('HTTP::DAV::Comms');

ok (
    defined &HTTP::DAV::UserAgent::redirect_ok
    && HTTP::DAV::UserAgent->can('redirect_ok'),
    'redirect_ok() is overridden in HTTP::DAV::UserAgent'
);

