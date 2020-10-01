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

my $test_domain = 'test.fastmail.com';
my $test_org_domain = Mail::DMARC::PurePerl->new->get_organizational_domain($test_domain);
is( $test_org_domain, 'fastmail.com', 'Mail::DMARC public suffix list correctly functioning' );

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');

{
  my $bimi = Mail::BIMI->new;
  $bimi->resolver($resolver);

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result->result( 'pass' );
  $dmarc->result->disposition( 'reject' );
  $bimi->dmarc_object( $dmarc->result );

  $bimi->domain( 'gallifreyburning.com' );
  $bimi->selector( 'FAKEfoobar' );

  my $record = $bimi->record;
  $record->record_hashref;
  is_deeply( $record->domain, 'gallifreyburning.com', 'Fallback domain' );
  is_deeply( $record->selector, 'default', 'Fallback selector' );
}

{
  my $bimi = Mail::BIMI->new;
  $bimi->resolver($resolver);

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result->result( 'pass' );
  $dmarc->result->disposition( 'reject' );
  $bimi->dmarc_object( $dmarc->result );

  $bimi->domain( 'no.domain.gallifreyburning.com' );
  $bimi->selector( 'FAKEfoobar' );

  my $record = $bimi->record;
  $record->record_hashref;

  is_deeply( $record->domain, 'gallifreyburning.com', 'Fallback domain' );
  is_deeply( $record->selector, 'default', 'Fallback selector' );
}

done_testing;
