#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
BEGIN { $ENV{MAIL_BIMI_CACHE_BACKEND} = 'Null' };
use lib 't';
use Mail::BIMI::Prelude;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;

my $bimi = Mail::BIMI->new( domain => 'test.example.com', selector => 'default' );
my $record = Mail::BIMI::Record->new( bimi_object => $bimi, domain => 'test.example.com', selector => 'default' );
$record->record_hashref( $record->_parse_record( 'v=bimi1; l=https://bimi.example.com/marks/' ) );
$bimi->record($record);

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
is( $auth_results, 'bimi=skipped (No DMARC)', 'authresults' );
is ( $result->domain, 'test.example.com', 'result domain' );
is ( $result->selector, 'default', 'result selector' );

done_testing;
