#!usr/bin/env perl
use strict;
use Test::More;

use HTTP::Thin::UserAgent;
use Test::Requires::Env qw(
  LIVE_HTTP_TESTS
);

{
    my $uri  = 'http://perigr.in/will-never-exist-'.time;
    my $resp = http( GET $uri )->on_error(sub {
        note "$_";
        ok ref $_, 'got an exception object';
        is $_->status_code, '404', 'got a 404';
        is ref $_->response, 'HTTP::Response', 'got a response object too';
        ok $_->DOES('HTTP::Throwable::Role::Status::NotFound'), 'DOES NotFound properly';
    })->response;
}

done_testing;
