#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
    use Data::Dumper;

use Mail::BIMI;
use Mail::BIMI::Record;
use Mail::DMARC::PurePerl;

plan tests => 3;

process_bimi( 'test.example.com', 'default', 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'pass', 'reject',
    'bimi=pass header.d=test.example.com selector=default', 'Pass' );
process_bimi( 'test.example.com', 'default', 'v=bimi1; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'fail', 'reject',
    'bimi=skipped (DMARC fail)', 'DMARC Fail');
process_bimi( 'test.example.com', 'default', 'v=foobar; f=png,svg; z=256x256,512x512,1024x1024; l=https://bimi.example.com/marks/', 'pass', 'reject',
    'bimi=fail (Invalid BIMI Record)', 'Skipped Invalid');

sub process_bimi {
    my ( $Domain, $Selector, $Entry, $DMARC_Result, $DMARC_Disposition, $ExpectedResult, $Test ) = @_;
    my $BIMI = Mail::BIMI->new();

    my $Record = Mail::BIMI::Record->new({ 'record' => $Entry, 'domain' => $Domain, 'selector' => $Selector });
    $BIMI->{ 'record' } = $Record;

    $BIMI->set_from_domain( $Domain );
    $BIMI->set_selector( $Selector );
    $BIMI->set_dmarc_object( get_dmarc_result( $DMARC_Result, $DMARC_Disposition ) );
    $BIMI->validate();

    my $Result = $BIMI->result();
    my $AuthResults = $Result->get_authentication_results();
    is( $AuthResults, $ExpectedResult, $Test );
}

sub get_dmarc_result {
    my ( $Result, $Disposition ) = @_;
    my $DMARC = Mail::DMARC::PurePerl->new();
    $DMARC->result()->result( $Result );
    $DMARC->result()->disposition( $Disposition );
    return $DMARC->result();
}

