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

my $bimi = Mail::BIMI->new;

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );

$bimi->domain( 'dnslookupnorecord.com' );
$bimi->selector( 'foobar' );

my $record = $bimi->record;

is_deeply(
    [ $record->is_valid(), $record->error_codes ],
    [ 0, ['NO_BIMI_RECORD'] ],
    'Test record does not validate'
);

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=none (No BIMI records found)';
is( $auth_results, $expected_result, 'Auth results correcct' );

is_deeply( $result->headers, {}, 'headers' );

done_testing;
