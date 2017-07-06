package Mail::BIMI;

use strict;
use warnings;

our $VERSION = '1.20170626'; # VERSION

use Carp;
use English qw( -no_match_vars );
use Data::Dumper;

use Net::DNS::Resolver;

use Mail::BIMI::Record;
use Mail::BIMI::Result;

use constant NO_BIMI_RECORD => 'no BIMI records found';

sub new {
    my ( $Class ) = @_;
    my $Self = {
        'from_domain'  => undef,
        'selector'     => 'default',
        'dmarc_object' => undef,
        'resolver'     => undef,
        'record'       => undef,
        'result'       => undef,
    };
    bless $Self, ref($Class) || $Class;
    return $Self;
}

sub set_from_domain {
    my ( $Self, $From ) = @_;
    $Self->{ 'from_domain' } = $From;
    return;
}

sub set_selector {
    my ( $Self, $Selector ) = @_;
    $Self->{ 'selector' } = $Selector;
    return;
}

sub set_dmarc_object {
    my ( $Self, $DMARC ) = @_;
    ## Check type of passed object here
    $Self->{ 'dmarc_object' } = $DMARC;
    return;
}

sub set_resolver {
    my ( $Self, $Resolver ) = @_;
    $Self->{ 'resolver' } = $Resolver;
    return;
}

sub get_resolver {
    my ( $Self ) = @_;
    return $Self->{ 'resolver' } if defined $Self->{ 'resolver' };
    my $Timeout = $Self->config( 'TImeout' );
    $Self->{ 'resolver' } = Net::DNS::Resolver->new( 'dnsrch' => 0 );
    $Self->{ 'resolver' }->tcp_timeout( $Timeout );
    $Self->{ 'resolver' }->udp_timeout( $Timeout );
    return $Self->{ 'resolver' };
}

sub config {
    my ( $Self, $Item ) = @_;
    my $Config = {
        'Timeout' => 5,
    };
    return $Config->{ $Item };
}

sub validate {
    my ( $Self ) = @_;

    my $Result = Mail::BIMI::Result->new();
    $Self->{ 'result' } = $Result;

    $Result->set_domain( $Self->{ 'from_domain' } );
    $Result->set_selector( $Self->{ 'selector' } );

    # does DMARC pass
    my $DMARC = $Self->{ 'dmarc_object' };
    if ( ! $DMARC ) {
        $Result->set_result( 'skipped', 'no DMARC' );
        return;
    }
    if ( $DMARC->result() ne 'pass' ) {
        $Result->set_result( 'skipped', 'DMARC ' . $DMARC->result() );
        return;
    }

    # Lookup, parse, and validate BIMI record
    # ONLY discover is we have an authenticated message
    if ( ! defined $Self->{ 'record' } ) {
        $Self->discover_bimi_record();
    }

    my $Record = $Self->record();

    if ( ! $Record ) {
        $Result->set_result( 'none', 'No BIMI Record' );
        return;
    }

    if ( ! $Record->is_valid() ) {
        my $LookFor = NO_BIMI_RECORD;
        if ( $Record->error() =~ /$LookFor/ ) {
            $Result->set_result( 'none', 'Domain is not BIMI enabled' );
        }
        else {
            $Result->set_result( 'fail', 'Invalid BIMI Record' );
        }
        return;
    }

    $Result->set_result( 'pass' );

    # Build results object
}

sub discover_bimi_record {
    my ( $Self, $Domain, $Selector ) = @_;

    $Domain   = $Self->{ 'from_domain' } if ! $Domain;
    $Selector = $Self->{ 'selector' }    if ! $Selector;
    my $LookupRecord = $Selector. '._bimi.' . $Domain;
    my @Records = eval { $Self->get_dns_rr( 'TXT', $LookupRecord ); };
    if ( my $Error = $@ ) {
        $Self->{ 'record' } = Mail::BIMI::Record->new({ 'domain' => $Domain, 'selector' => $Selector });
        $Self->{ 'record' }->error( 'error querying DNS' );
        return;
    }
    # Filter records
    @Records = grep { $_ =~ /^v=bimi1;/i } @Records;
    if ( scalar @Records == 0 ) {
        my $FallbackSelector = 'default';
        my $FallbackDomain   = $Self->get_org_domain( $Domain );
        if ( $FallbackSelector eq $Selector && $FallbackDomain eq $Domain ) {
            $Self->{ 'record' } = Mail::BIMI::Record->new();
            $Self->{ 'record' }->error( NO_BIMI_RECORD );
            # Set result none
            #
            return;
        }
        return $Self->discover_bimi_record( $FallbackDomain, $FallbackSelector );
    }
    elsif ( scalar @Records > 1 ) {
        $Self->{ 'record' } = Mail::BIMI::Record->new({ 'domain' => $Domain, 'selector' => $Selector });
        $Self->{ 'record' }->error( 'multiple BIMI records found' );
        # Set result fail
    }
    else {
        # We have one record, let's use that.
        $Self->{ 'record' } = Mail::BIMI::Record->new({ 'record' => $Records[0], 'domain' => $Domain, 'selector' => $Selector });
    }

    return;
}

sub record {
    my ( $Self ) = @_;
    return $Self->{ 'record' };
}

sub result {
    my ( $Self ) = @_;
    return $Self->{ 'result' };
}

sub get_org_domain {
    my ( $Self, $Domain ) = @_;
    my $DMARC = Mail::DMARC::PurePerl->new();
    my $OrgDomain = $DMARC->get_organizational_domain( $Domain );
    return $OrgDomain;
}

sub get_dns_rr {
    my ( $Self, $Type, $Domain ) = @_;

    my @Matches;
    my $Res     = $Self->get_resolver();
    my $Query   = $Res->query( $Domain, $Type ) or do {
        return @Matches;
    };
    for my $rr ( $Query->answer ) {
        next if $rr->type ne $Type;
        push @Matches, $rr->type eq  'A'   ? $rr->address
                     : $rr->type eq 'PTR'  ? $rr->ptrdname
                     : $rr->type eq  'NS'  ? $rr->nsdname
                     : $rr->type eq  'TXT' ? $rr->txtdata
                     : $rr->type eq  'SPF' ? $rr->txtdata
                     : $rr->type eq 'AAAA' ? $rr->address
                     : $rr->type eq  'MX'  ? $rr->exchange
                     : $rr->answer;
    }
    return @Matches;
}

1;

# ABSTRACT: BIMI parser
__END__

