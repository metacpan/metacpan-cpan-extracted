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
 'identity'      => 'test@spfnall.gallifreyburning.com',
 'ip_address'    => '66.111.4.25',
 'helo_identity' => 'spfnall.galllifreyburning.com',
);

my $spf_result = $spf_server->process($spf_request);

my $bimi = Mail::BIMI->new();
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );
$bimi->spf_object( $spf_result );

$bimi->domain( 'spfall.gallifreyburning.com' );
$bimi->selector( 'default' );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=pass header.d=spfall.gallifreyburning.com selector=default';
is( $auth_results, $expected_result, 'Auth results correcct' );

done_testing;
