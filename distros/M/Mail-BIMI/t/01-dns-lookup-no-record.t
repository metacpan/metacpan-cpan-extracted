#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC::PurePerl;

my $bimi = Mail::BIMI->new;
my $dmarc = Mail::DMARC::PurePerl->new;
$dmarc->result->result( 'pass' );
$dmarc->result->disposition( 'reject' );
$bimi->dmarc_object( $dmarc->result );

$bimi->domain( 'gallifreyburning.org' );
$bimi->selector( 'foobar' );

my $record = $bimi->record;

is_deeply(
    [ $record->is_valid(), $record->error() ],
    [ 0, ['no BIMI records found'] ],
    'Test record does not validate'
);

my $result = $bimi->result;
my $auth_results = $result->get_authentication_results;
my $expected_result = 'bimi=none (Domain is not BIMI enabled)';
is( $auth_results, $expected_result, 'Auth results correcct' );

done_testing;
