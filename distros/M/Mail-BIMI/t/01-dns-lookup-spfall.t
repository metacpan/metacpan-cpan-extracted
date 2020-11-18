#!perl
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
use Mail::DMARC::PurePerl;
use Mail::SPF::Server;
use Mail::SPF::Request;
use Net::DNS::Resolver::Mock 1.20200214;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');

my $spf_server = Mail::SPF::Server->new(
  'dns_resolver' => $resolver,
);

my $spf_request = Mail::SPF::Request->new(
 'versions'      => [1],
 'scope'         => 'mfrom',
 'identity'      => 'test@dnslookupspfall.com',
 'ip_address'    => '66.111.4.25',
 'helo_identity' => 'dnslookupspfall.com',
);

my $spf_result = $spf_server->process($spf_request);

my $bimi = Mail::BIMI->new;
$bimi->options->strict_spf(1);
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );
$bimi->spf_object( $spf_result );

$bimi->domain( 'dnslookupspfall.com' );
$bimi->selector( 'default' );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=skipped (SPF +all detected)';
is( $auth_results, $expected_result, 'Auth results correcct' );

is_deeply( $result->headers, {}, 'headers' );

done_testing;
