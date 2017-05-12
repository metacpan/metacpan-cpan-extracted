#!/usr/bin/perl

# $Id: 01-compile.t 38877 2006-07-12 12:16:51Z nanardon $

use strict;
use warnings;

use Test::More tests => 4;

use_ok('MDV::Distribconf::Checks');

MDV::Distribconf::Checks::_report_err(
    sub {
        my %err = @_;
        is($err{errcode}, 'UNSYNC_HDLIST', 'get proper errcode');
        is($err{level}, 'E', 'get proper err level');
        ok($err{message}, 'get message');
    },
    'UNSYNC_HDLIST',
    'test message',
);

