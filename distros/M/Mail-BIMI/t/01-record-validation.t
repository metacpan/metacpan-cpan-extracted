#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

plan tests => 19;

is_deeply(
    test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 1, '' ],
    'Valid record'
);

is_deeply(
    test_record( 'v=bimi1; v=bimi2; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Duplicate key in record, Invalid v tag' ],
    'Dupliacte key'
);

is_deeply(
    test_record( 'f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Missing v tag' ],
    'Missing v tag'
);
is_deeply(
    test_record( 'v=; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Empty v tag, Invalid v tag' ],
    'Empty v tag'
);
is_deeply(
    test_record( 'v=foobar; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Invalid v tag' ],
    'Invalid v tag'
);

is_deeply(
    test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024', 'example.com', 'default' ),
    [ 0, 'Missing l tag' ],
    'Missing l tag'
);
is_deeply(
    test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=http://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Invalid transport in l tag' ],
    'Invalid transport in l tag'
);
is_deeply(
    test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=foo,,bar', 'example.com', 'default' ),
    [ 0, 'Invalid transport in l tag, Empty l tag, Invalid transport in l tag, Invalid transport in l tag' ],
    'Empty l entry'
);
is_deeply(
    test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=', 'example.com', 'default' ),
    [ 0, 'Empty l tag' ],
    'Empty l tag'
);

is_deeply(
    test_record( 'v=bimi1; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 1, '' ],
    'Missing f tag'
);
is_deeply( test_record( 'v=bimi1; f=; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Empty f entry' ],
    'Empty f tag'
);
is_deeply( test_record( 'v=bimi1; f=png,,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Empty f entry' ],
    'Empty f entry'
);
is_deeply( test_record( 'v=bimi1; f=exe; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Unknown value in f tag' ],
    'Unknown f entry'
);

is_deeply( test_record( 'v=bimi1; f=png,svg; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Missing z tag' ],
    'Missing z tag'
);
is_deeply( test_record( 'v=bimi1; f=png,svg; z=; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 1, '' ],
    'Empty z tag'
);
is_deeply( test_record( 'v=bimi1; f=png,svg; z=256x256,,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Empty z entry' ],
    'Empty z entry'
);
is_deeply( test_record( 'v=bimi1; f=png,svg; z=foobar; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Invalid z tag, Invalid z tag' ],
    'Invalid z tag'
);
is_deeply( test_record( 'v=bimi1; f=png,svg; z=1x1,512x512,1024x1024; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Invalid dimension in z tag, Invalid dimension in z tag' ],
    'z too small'
);
is_deeply( test_record( 'v=bimi1; f=png,svg; z=256x256,512x512,10240x10240; l=https://bimi.example.com/marks/', 'example.com', 'default' ),
    [ 0, 'Invalid dimension in z tag, Invalid dimension in z tag' ],
    'z too large'
);

sub test_record {
    my ( $Entry, $Domain, $Selector ) = @_;
    my $Record = Mail::BIMI::Record->new({ 'record' => $Entry, 'domain' => $Domain, 'selector' => $Selector });
    return [ $Record->is_valid(), $Record->error() ];;
}

