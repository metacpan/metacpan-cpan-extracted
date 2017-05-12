package TestEventHandler;
#
#   Finance::InteractiveBrokers::SWIG - Test EventHandler subclass
#
#   Copyright (c) 2010-2014 Jason McManus
#

use Carp qw( croak confess );
use Test::More;
use strict;
use warnings;

# Ours
use base qw( Finance::InteractiveBrokers::SWIG::EventHandler );

###
### Variables
###

use vars qw( $VERSION );
BEGIN {
    $VERSION = '0.13';
}

###
### Methods
###

sub winError              { pass( 'TestEventHandler: winError' ); }
sub error                 { pass( 'TestEventHandler: error' ); }
sub connectionClosed      { pass( 'TestEventHandler: connectionClosed' ); }
sub currentTime           { pass( 'TestEventHandler: currentTime' ); }

sub tickPrice             { pass( 'TestEventHandler: tickPrice' ); }
sub tickSize              { pass( 'TestEventHandler: tickSize' ); }
sub tickOptionComputation { pass( 'TestEventHandler: tickOptionComputation' ); }
sub tickGeneric           { pass( 'TestEventHandler: tickGeneric' ); }
sub tickString            { pass( 'TestEventHandler: tickString' ); }
sub tickEFP               { pass( 'TestEventHandler: tickEFP' ); }
sub tickSnapshotEnd       { pass( 'TestEventHandler: tickSnapshotEnd' ); }

sub orderStatus           { pass( 'TestEventHandler: orderStatus' ); }
sub openOrder             { pass( 'TestEventHandler: openOrder' ); }
sub nextValidId           { pass( 'TestEventHandler: nextValidId' ); }

sub updateAccountValue    { pass( 'TestEventHandler: updateAccountValue' ); }
sub updatePortfolio       { pass( 'TestEventHandler: updatePortfolio' ); }
sub updateAccountTime     { pass( 'TestEventHandler: updateAccountTime' ); }

sub updateNewsBulletin    { pass( 'TestEventHandler: updateNewsBulletin' ); }

sub contractDetails       { pass( 'TestEventHandler: contractDetails' ); }
sub contractDetailsEnd    { pass( 'TestEventHandler: contractDetailsEnd' ); }
sub bondContractDetails   { pass( 'TestEventHandler: bondContractDetails' ); }

sub execDetails           { pass( 'TestEventHandler: execDetails' ); }
sub execDetailsEnd        { pass( 'TestEventHandler: execDetailsEnd' ); }

sub updateMktDepth        { pass( 'TestEventHandler: updateMktDepth' ); }
sub updateMktDepthL2      { pass( 'TestEventHandler: updateMktDepthL2' ); }

sub managedAccounts       { pass( 'TestEventHandler: managedAccounts' ); }
sub receiveFA             { pass( 'TestEventHandler: receiveFA' ); }

sub historicalData        { pass( 'TestEventHandler: historicalData' ); }

sub scannerParameters     { pass( 'TestEventHandler: scannerParameters' ); }
sub scannerData           { pass( 'TestEventHandler: scannerData' ); }
sub scannerDataEnd        { pass( 'TestEventHandler: scannerDataEnd' ); }

sub realtimeBar           { pass( 'TestEventHandler: realtimeBar' ); }

sub fundamentalData       { pass( 'TestEventHandler: fundamentalData' ); }

sub deltaNeutralValidation { pass( 'TestEventHandler: deltaNeutralValidation' ); }

# These are in the headers, but not documented in the IB API docs
sub openOrderEnd          { pass( 'TestEventHandler: openOrderEnd' ); }
sub accountDownloadEnd    { pass( 'TestEventHandler: accountDownloadEnd' ); }

# This is new as of 9.66
sub marketDataType        { pass( 'TestEventHandler: marketDataType' ); }

# This is new as of 9.67
sub commissionReport      { pass( 'TestEventHandler: commissionReport' ); }

1;

__END__
