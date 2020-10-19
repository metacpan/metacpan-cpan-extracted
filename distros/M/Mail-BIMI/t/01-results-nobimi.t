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
use Net::DNS::Resolver::Mock 1.20200214;

my $bimi = Mail::BIMI->new();

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );

$bimi->domain( 'resultsnobimi.com' );
$bimi->selector( 'default' );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
is( $auth_results, 'bimi=none (No BIMI records found)', 'authresults' );
is ( $result->domain, 'resultsnobimi.com', 'result domain' );
is ( $result->selector, 'default', 'result selector' );

sub get_dmarc_result {
  my ( $result, $disposition ) = @_;
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->result()->result( $result );
  $dmarc->result()->disposition( $disposition );
  return $dmarc->result;
}

done_testing;
