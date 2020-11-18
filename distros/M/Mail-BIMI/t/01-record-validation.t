#!/perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::RequiresInternet;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;

plan tests => 11;

is_deeply(
  test_record( 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record'
);

is_deeply(
  test_record( 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg;', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with terminator'
);

is_deeply(
  test_record( 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg; a=', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with a'
);

is_deeply(
  test_record( 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg; a=;', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with a and terminator'
);

is_deeply(
  test_record( 'v=bimi1; v=bimi2; l=https://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 0, ['DUPLICATE_KEY','INVALID_V_TAG'] ],
  'Dupliacte key'
);

is_deeply(
  test_record( 'l=https://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 0, ['MISSING_V_TAG'] ],
  'Missing v tag'
);
is_deeply(
  test_record( 'v=; l=https://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 0, ['EMPTY_V_TAG', 'INVALID_V_TAG'] ],
  'Empty v tag'
);
is_deeply(
  test_record( 'v=foobar; l=https://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 0, ['INVALID_V_TAG'] ],
  'Invalid v tag'
);

is_deeply(
  test_record( 'v=bimi1', 'example.com', 'default' ),
  [ 0, ['MISSING_L_TAG'] ],
  'Missing l tag'
);
is_deeply(
  test_record( 'v=bimi1; l=http://fastmaildmarc.com/FM_BIMI.svg', 'example.com', 'default' ),
  [ 0, ['INVALID_TRANSPORT_L'] ],
  'Invalid transport in location'
);
is_deeply(
  test_record( 'v=bimi1; l=', 'example.com', 'default' ),
  [ 0, ['EMPTY_L_TAG'] ],
  'Empty l tag'
);

sub test_record {
  my ( $entry, $domain, $selector ) = @_;
  my $bimi = Mail::BIMI->new;
  my $record = Mail::BIMI::Record->new( bimi_object => $bimi, domain => $domain, selector => $selector );
  $record->record_hashref( $record->_parse_record( $entry ) );
  $record->is_valid;
  return [ $record->is_valid, $record->error_codes ];
}

#!perl
