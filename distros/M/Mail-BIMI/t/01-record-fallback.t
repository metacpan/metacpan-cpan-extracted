#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;

use Mail::BIMI;
use Mail::BIMI::Record;

use Mail::DMARC::PurePerl;

plan tests => 4;

{
    my $BIMI = Mail::BIMI->new();

    my $DMARC = Mail::DMARC::PurePerl->new();
    $DMARC->result()->result( 'pass' );
    $DMARC->result()->disposition( 'reject' );
    $BIMI->set_dmarc_object( $DMARC->result() );

    $BIMI->set_from_domain( 'gallifreyburning.com' );
    $BIMI->set_selector( 'FAKEfoobar' );
    $BIMI->validate();

    my $Record = $BIMI->record();

    is_deeply( $Record->{'domain'}, 'gallifreyburning.com', 'Fallback domain' );
    is_deeply( $Record->{'selector'}, 'default', 'Fallback selector' );
}

{
    my $BIMI = Mail::BIMI->new();

    my $DMARC = Mail::DMARC::PurePerl->new();
    $DMARC->result()->result( 'pass' );
    $DMARC->result()->disposition( 'reject' );
    $BIMI->set_dmarc_object( $DMARC->result() );

    $BIMI->set_from_domain( 'no.domain.gallifreyburning.com' );
    $BIMI->set_selector( 'FAKEfoobar' );
    $BIMI->validate();

    my $Record = $BIMI->record();

    is_deeply( $Record->{'domain'}, 'gallifreyburning.com', 'Fallback domain' );
    is_deeply( $Record->{'selector'}, 'default', 'Fallback selector' );
}

