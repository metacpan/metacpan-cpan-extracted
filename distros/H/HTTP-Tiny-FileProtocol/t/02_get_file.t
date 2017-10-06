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
    File::Spec->catfile( dirname( __FILE__ ), 'test.txt' ),
);

my $content = do{ local (@ARGV, $/) = $file; <> };
my $response = $http->get('file://' . $file);

delete $response->{url};

my $content_length;
{
    use bytes;
    $content_length = length $content;
}

my $check = {
    success => 1,
    status  => 200,
    content => $content // '',
    headers => {
        'content-type'   => 'text/plain',
        'content-length' => $content_length // 0,
    },
};

is $response->{status}, 200;
is_deeply $response, $check;
is_string $content, $response->{content};

done_testing();
