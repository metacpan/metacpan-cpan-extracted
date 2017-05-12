#!/usr/bin/perl

use strict;
use Finance::InteractiveBrokers::TWS;

my $callback = Local::Callback->new();
my $tws      = Finance::InteractiveBrokers::TWS->new($callback);

my $tick_type = $tws->TickType->new();
$callback->{tickType} = $tick_type;

#                           Host         Port    Client_ID
#                           ----         ----    ---------
my @tws_GUI_location = qw/  127.0.0.1    7496       15     /;

$tws->eclient->eConnect(@tws_GUI_location);

do {$tws->read_messages_for_x_sec()} until 
	$tws->eclient->isConnected();

#  Create a contract
#
my $contract_id = 50;     # this can be any number you want
my $contract    = $tws->Contract->new();

#  Set the values
$contract->{m_conId}    = $contract_id;
$contract->{m_symbol}   = 'AAPL';
$contract->{m_secType}  = 'STK';
$contract->{m_exchange} = 'SMART';

$tws->eclient->reqMktData($contract_id, $contract,"","");

while(1) {
   $tws->read_messages_for_x_sec();
}

package Local::Callback;

sub new {
	bless {}, shift;
}

sub nextValidId {
	my $self = shift;
	$self->{nextValidId} = $_[0];
	print "nextValidId called with: ", join(" ", @_), "\n";
}

sub tickPrice {
	my ($self, $tickerId, $tickType, @data) = @_;
	my $type = $self->{tickType}->getField($tickType);
	print "$type: ", join("\t", @data),"\n";
}

sub AUTOLOAD { # catch all for other events
	my ($self, @args) = @_;
	our $AUTOLOAD;
	print "$AUTOLOAD called with: ", join '^', @args, "\n";
	return 0;
}

