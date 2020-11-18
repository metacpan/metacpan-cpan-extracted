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
use Net::DNS::Resolver::Mock 1.20200214;

my $bimi = Mail::BIMI->new();

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );

$bimi->domain( 'dnslookupcname.com' );
$bimi->selector( 'selector' );

my $record = $bimi->record;

is_deeply(
    [ $record->is_valid, $record->error_codes ],
    [ 1, [] ],
    'Test record validates'
);

my $expected_data = {
    'l' => 'https://fastmaildmarc.com/FM_BIMI.svg',
    'v' => 'bimi1'
};

is_deeply( $record->record_hashref, $expected_data, 'Parsed data' );

my $expected_url = 'https://fastmaildmarc.com/FM_BIMI.svg';
is_deeply( $record->location->uri, $expected_url, 'URL' );

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=pass header.d=dnslookupcname.com header.selector=selector';
is( $auth_results, $expected_result, 'Auth results correct' );

done_testing;
