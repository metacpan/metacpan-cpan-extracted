#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

use Mail::DMARC::PurePerl;

plan tests => 3;

my $BIMI = Mail::BIMI->new();

my $DMARC = Mail::DMARC::PurePerl->new();
$DMARC->result()->result( 'pass' );
$DMARC->result()->disposition( 'reject' );
$BIMI->set_dmarc_object( $DMARC->result() );

$BIMI->set_from_domain( 'gallifreyburning.com' );
$BIMI->set_selector( 'foobar' );
$BIMI->validate();

my $Record = $BIMI->record();

is_deeply(
    [ $Record->is_valid(), $Record->error() ],
    [ 1, '' ],
    'Test record validates'
);

my $ExpectedData = {
    'z' => [
        '256x256',
        '512x512',
        '1024x1024'
    ],
    'f' => [
        'png',
        'jpg'
    ],
    'l' => [
        'https://bimi.example.com/marks/baz/'
    ],
    'v' => 'bimi1'
};

is_deeply( $Record->data(), $ExpectedData, 'Parsed data' );

my $ExpectedUrlList = [
    'https://bimi.example.com/marks/baz/256x256.png',
    'https://bimi.example.com/marks/baz/256x256.jpg',
    'https://bimi.example.com/marks/baz/512x512.png',
    'https://bimi.example.com/marks/baz/512x512.jpg',
    'https://bimi.example.com/marks/baz/1024x1024.png',
    'https://bimi.example.com/marks/baz/1024x1024.jpg'
];

is_deeply( $Record->url_list(), $ExpectedUrlList, 'URL list' );

