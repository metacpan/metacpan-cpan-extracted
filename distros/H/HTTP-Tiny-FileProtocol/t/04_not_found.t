#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;
use File::Spec;

use HTTP::Tiny;
use HTTP::Tiny::FileProtocol;

my $http = HTTP::Tiny->new;
isa_ok $http, 'HTTP::Tiny';

my $file = File::Spec->rel2abs(
    File::Spec->catfile( dirname( __FILE__ ), 'ascii_table3.xlsx' )
);

my $response = $http->get('file://' . $file);

delete $response->{url};

my $check = {
    success => undef,
    status  => 404,
    reason  => 'File Not Found',
    content => '',
    headers => {
        'content-type'   => 'text/plain',
        'content-length' => 0,
    },
};

is $response->{status}, 404;
is_deeply $response, $check;

done_testing();
