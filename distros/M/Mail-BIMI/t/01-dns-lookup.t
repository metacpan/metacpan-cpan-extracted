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

my $bimi = Mail::BIMI->new();

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_read('t/zonefile');
$bimi->resolver($resolver);

my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );

$bimi->domain( 'dnslookup.com' );
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
my $expected_result = 'bimi=pass header.d=dnslookup.com header.selector=selector';
is( $auth_results, $expected_result, 'Auth results correct' );

my $expected_headers = {
  'BIMI-Indicator' => 'PHN2ZyB2ZXJzaW9uPSIxLjIiIGJhc2VQcm9maWxlPSJ0aW55LXBzIiB4bWxucz0iaHR0cD
    ovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDI0IiBoZWlnaHQ9IjEwMjQiIHZp
    ZXdCb3g9IjAgMCAxMDI0IDEwMjQiPjx0aXRsZT5GTS1JY29uLVJHQjwvdGl0bGU+PGcgaW
    Q9IkFydHdvcmsiPjxyZWN0IHdpZHRoPSIxMDI0IiBoZWlnaHQ9IjEwMjQiIGZpbGw9IiNG
    RkZGRkYiLz48cGF0aCBkPSJNMTIwLjE2LDUxMmMwLTIxNi40LDE3NS40My0zOTEuODQsMz
    kxLjg0LTM5MS44NCwxMzYsMCwyNTUuNzEsNjkuMzQsMzI2LDE3NC41M2w3Ny4xOSwxNS4y
    MSw5LjU4LTczLjA2Yy04OS0xMzMuMTgtMjQwLjU2LTIyMS00MTIuNzQtMjIxQzIzOCwxNS
    44NywxNS44NywyMzgsMTUuODcsNTEyQTQ5My43OCw0OTMuNzgsMCwwLDAsOTkuMTksNzg3
    LjIxbDc0LjcyLDkuNjhMMTg2LDcyOS4zNUEzOTAsMzkwLDAsMCwxLDEyMC4xNiw1MTJaIi
    BmaWxsPSIjMDA2N2I5Ii8+PHBhdGggZD0iTTkyNiwyMzguNjRjLS40MS0uNjEtLjgzLTEu
    Mi0xLjI0LTEuOEw4MzgsMjk0LjY5Yy40MS42LjgzLDEuMTksMS4yMywxLjhBMzg5LjkxLD
    M4OS45MSwwLDAsMSw5MDMuODMsNTEyYzAsMjE2LjQtMTc1LjQzLDM5MS44NC0zOTEuODMs
    MzkxLjg0LTEzNS4yMSwwLTI1NC40Mi02OC40OS0zMjQuODQtMTcyLjY2LS40MS0uNi0uNz
    ktMS4yMi0xLjE5LTEuODNMOTkuMTksNzg3LjIxYy40MS42Ljc4LDEuMjIsMS4xOSwxLjgz
    QzE4OS41MSw5MjEuMiwzNDAuNiwxMDA4LjEzLDUxMiwxMDA4LjEzYzI3NCwwLDQ5Ni4xMy
    0yMjIuMTMsNDk2LjEzLTQ5Ni4xM0E0OTMuNjgsNDkzLjY4LDAsMCwwLDkyNiwyMzguNjRa
    IiBmaWxsPSIjNjliM2U3Ii8+PHBhdGggZD0iTTUxMiw1MTIsMjc2LjE1LDM1NC43NlY2Nj
    kuMjNoMGwxNDguMi00NS44NloiIGZpbGw9IiNmZmMxMDciLz48cGF0aCBkPSJNMjc2LjE1
    LDY2OS4yNEg3MzEuMjdhMTYuNTgsMTYuNTgsMCwwLDAsMTYuNTgtMTYuNTlWMzU0Ljc2Wi
    IgZmlsbD0iIzMzM2U0OCIvPjwvZz48L3N2Zz4K',
  'BIMI-Location' => 'v=BIMI1;
    l=https://fastmaildmarc.com/FM_BIMI.svg'
        };
is_deeply( $result->headers, $expected_headers, 'headers' );

done_testing;
