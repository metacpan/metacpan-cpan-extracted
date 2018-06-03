#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use List::Breakdown 'breakdown';

our $VERSION = '0.22';

my @checks = (
    {
        hostname => 'webserver1',
        status   => 'OK',
    },
    {
        hostname => 'webserver2',
        status   => 'CRITICAL',
    },
    {
        hostname => 'webserver3',
        status   => 'WARNING',
    },
    {
        hostname => 'webserver4',
        status   => 'OK',
    },
);

my %buckets = (
    ok      => sub { $_->{status} eq 'OK' },
    problem => {
        warning  => sub { $_->{status} eq 'WARNING' },
        critical => sub { $_->{status} eq 'CRITICAL' },
        unknown  => sub { $_->{status} eq 'UNKNOWN' },
    },
);

my %results = breakdown \%buckets, @checks;

my %expected = (
    ok => [
        {
            hostname => 'webserver1',
            status   => 'OK',
        },
        {
            hostname => 'webserver4',
            status   => 'OK',
        },
    ],
    problem => {
        warning => [
            {
                hostname => 'webserver3',
                status   => 'WARNING',
            },
        ],
        critical => [
            {
                hostname => 'webserver2',
                status   => 'CRITICAL',
            },
        ],
        unknown => [],
    },
);

is_deeply( \%results, \%expected, 'monitoring' );
