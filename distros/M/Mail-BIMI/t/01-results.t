#!perl
use 5.20.0;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Mail::BIMI::Pragmas;
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC::PurePerl;

process_bimi( 'test.example.com', 'default', 'v=bimi1; l=https://bimi.example.com/marks/', 'pass', 'reject',
    'bimi=pass header.d=test.example.com selector=default', 'Pass' );
process_bimi( 'test.example.com', 'default', 'v=bimi1; l=https://bimi.example.com/marks/', 'fail', 'reject',
    'bimi=skipped (DMARC fail)', 'DMARC Fail');
process_bimi( 'test.example.com', 'default', 'v=foobar; l=https://bimi.example.com/marks/', 'pass', 'reject',
    'bimi=fail (Invalid BIMI Record)', 'Skipped Invalid');

sub process_bimi {
  my ( $domain, $selector, $entry, $dmarc_result, $dmarc_disposition, $expected_result, $test ) = @_;

  my $record = Mail::BIMI::Record->new( domain => $domain, selector => $selector );
  $record->record( $record->_parse_record( $entry ) );
  my $bimi = Mail::BIMI->new( domain => $domain, selector => $selector, record => $record, dmarc_object => get_dmarc_result( $dmarc_result, $dmarc_disposition ) );

  my $result = $bimi->result;
  my $auth_results = $result->get_authentication_results;
  is( $auth_results, $expected_result, $test );
}

sub get_dmarc_result {
  my ( $result, $disposition ) = @_;
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result()->result( $result );
  $dmarc->result()->disposition( $disposition );
  return $dmarc->result;
}

done_testing;
