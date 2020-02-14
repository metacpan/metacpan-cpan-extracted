#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::BIMI::Pragmas;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;

my $record = Mail::BIMI::Record->new( domain => 'test.example.com', selector => 'default' );
$record->record( $record->_parse_record( 'v=bimi1; l=https://bimi.example.com/marks/' ) );
my $bimi = Mail::BIMI->new( domain => 'test.example.com', selector => 'default', record => $record );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
is( $auth_results, 'bimi=skipped (No DMARC)', 'authresults' );
is ( $result->domain, 'test.example.com', 'result domain' );
is ( $result->selector, 'default', 'result selector' );

done_testing;
