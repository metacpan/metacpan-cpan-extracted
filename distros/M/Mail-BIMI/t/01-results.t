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
use Mail::DMARC::PurePerl;
use Net::DNS::Resolver::Mock 1.20200214;

process_bimi( 'results.com', 'default', 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg', 'pass', 'reject',
    'bimi=pass header.d=results.com header.selector=default', 'Pass' );
process_bimi( 'results.com', 'default', 'v=bimi1; l=https://fastmaildmarc.com/FM_BIMI.svg', 'fail', 'reject',
    'bimi=skipped (DMARC did not pass)', 'DMARC Fail');
process_bimi( 'results.com', 'default', 'v=foobar; l=https://fastmaildmarc.com/FM_BIMI.svg', 'pass', 'reject',
    'bimi=fail (Invalid v tag)', 'Skipped Invalid');

sub process_bimi {
  my ( $domain, $selector, $entry, $dmarc_result, $dmarc_disposition, $expected_result, $test ) = @_;

  my $bimi = Mail::BIMI->new( domain => $domain, selector => $selector );

  my $resolver = Net::DNS::Resolver::Mock->new;
  $resolver->zonefile_read('t/zonefile');
  $bimi->resolver($resolver);

  my $record = Mail::BIMI::Record->new( bimi_object => $bimi, domain => $domain, selector => $selector );
  $record->record_hashref( $record->_parse_record( $entry ) );
  $record->retrieved_domain($domain);
  $record->retrieved_selector($selector);
  $bimi->record($record);
  $bimi->dmarc_object( get_dmarc_result( $dmarc_result, $dmarc_disposition ) );

  my $result = $bimi->result;
  my $auth_results = $result->get_authentication_results;
  is( $auth_results, $expected_result, $test );
  is ( $result->domain, $domain, 'result domain' );
  is ( $result->selector, $selector, 'result selector' );
}

sub get_dmarc_result {
  my ( $result, $disposition ) = @_;
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result()->result( $result );
  $dmarc->result()->disposition( $disposition );
  return $dmarc->result;
}

done_testing;
