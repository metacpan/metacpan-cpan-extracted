#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

use Mail::DMARC::PurePerl;

plan tests => 2;

my $BIMI = Mail::BIMI->new();

my $DMARC = Mail::DMARC::PurePerl->new();
$DMARC->result()->result( 'pass' );
$DMARC->result()->disposition( 'reject' );
$BIMI->set_dmarc_object( $DMARC->result() );

$BIMI->set_from_domain( 'gallifreyburning.org' );
$BIMI->set_selector( 'foobar' );
$BIMI->validate();

my $Record = $BIMI->record();

is_deeply(
    [ $Record->is_valid(), $Record->error() ],
    [ 0, 'No record supplied, no BIMI records found' ],
    'Test record does not validate'
);

my $Result = $BIMI->result();
my $AuthResults = $Result->get_authentication_results();
my $ExpectedResult = 'bimi=none (Domain is not BIMI enabled)';
is( $AuthResults, $ExpectedResult, 'Auth results correcct' );

