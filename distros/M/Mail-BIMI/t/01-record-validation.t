#!/perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::BIMI::Pragmas;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;

plan tests => 12;

is_deeply(
  test_record( 'v=bimi1; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record'
);

is_deeply(
  test_record( 'v=bimi1; l=https://bimi.example.com/marks/file.svg;', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with terminator'
);

is_deeply(
  test_record( 'v=bimi1; l=https://bimi.example.com/marks/file.svg; a=', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with a'
);

is_deeply(
  test_record( 'v=bimi1; l=https://bimi.example.com/marks/file.svg; a=;', 'example.com', 'default' ),
  [ 1, [] ],
  'Valid record with a and terminator'
);

is_deeply(
  test_record( 'v=bimi1; v=bimi2; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 0, ['Duplicate key in record','Invalid v tag'] ],
  'Dupliacte key'
);

is_deeply(
  test_record( 'l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 0, ['Missing v tag'] ],
  'Missing v tag'
);
is_deeply(
  test_record( 'v=; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 0, ['Empty v tag', 'Invalid v tag'] ],
  'Empty v tag'
);
is_deeply(
  test_record( 'v=foobar; l=https://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 0, ['Invalid v tag'] ],
  'Invalid v tag'
);

is_deeply(
  test_record( 'v=bimi1', 'example.com', 'default' ),
  [ 0, ['Missing l tag'] ],
  'Missing l tag'
);
is_deeply(
  test_record( 'v=bimi1; l=http://bimi.example.com/marks/file.svg', 'example.com', 'default' ),
  [ 0, ['Invalid transport in locations'] ],
  'Invalid transport in locations'
);
is_deeply(
  test_record( 'v=bimi1; l=foo,,bar', 'example.com', 'default' ),
  [  0, ['Invalid transport in locations', 'Empty l tag', 'Invalid transport in locations'] ],
  'Empty l entry'
);
is_deeply(
  test_record( 'v=bimi1; l=', 'example.com', 'default' ),
  [ 0, ['Empty l tag'] ],
  'Empty l tag'
);

sub test_record {
  my ( $entry, $domain, $selector ) = @_;
  my $record = Mail::BIMI::Record->new( domain => $domain, selector => $selector );
  $record->record( $record->_parse_record( $entry ) );
  $record->is_valid;
  my @errors = ( $record->error->@*, $record->authorities->error->@*, $record->locations->error->@* );
  return [ $record->is_valid, \@errors ];
}

#!perl
