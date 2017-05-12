package Finance::CampBX;
$Finance::CampBX::VERSION = '0.2';
use strict;
use warnings;
use LWP::UserAgent;
use JSON -support_by_pp;

sub ticker(){	
	return sendrequest("http://campbx.com/api/xticker.php");	
}

sub depth(){	
	return sendrequest("http://campbx.com/api/xdepth.php");	
}

sub balance(){	 
	my $self = shift;
	my ($userid, $password) = @_;
	return sendrequest('https://campbx.com/api/myfunds.php', {'user'=>$userid, 'pass'=>$password });
}

sub orders(){	 
	my $self = shift;
	my ($userid, $password) = @_;
	return sendrequest('https://campbx.com/api/myorders.php', {'user'=>$userid, 'pass'=>$password });
}

sub margins(){	 
	my $self = shift;
	my ($userid, $password) = @_;
	return sendrequest('https://campbx.com/api/mymargins.php', {'user'=>$userid, 'pass'=>$password });
}

sub getbtcaddress(){	 
	my $self = shift;
	my ($userid, $password) = @_;
	return sendrequest('https://campbx.com/api/getbtcaddr.php', {'user'=>$userid, 'pass'=>$password });
}

sub quicktrade(){	 
	my $self = shift;
	my ($userid, $password, $trademode, $quantity, $price) = @_;
	return sendrequest('https://campbx.com/api/tradeenter.php', { 'user'=>$userid, 'pass'=>$password, 'TradeMode'=>$trademode,  'Quantity'=> $quantity,  'Price'=>$price });
}

sub cancelorder(){	 
	my $self = shift;
	my ($userid, $password, $type, $orderid) = @_;
	return sendrequest('https://campbx.com/api/tradecancel.php', { 'user'=>$userid, 'pass'=>$password, 'Type'=>$type,  'OrderID'=>$orderid });
}

sub sendtobtc(){	 
	my $self = shift;
	my ($userid, $password, $btcaddress, $btcamount) = @_;
	return sendrequest('https://campbx.com/api/sendbtc.php', { 'user'=>$userid, 'pass'=>$password, 'BTCTo'=>$btcaddress,  'BTCAmt'=>$btcamount });
}


sub sendrequest(){
	my ( $url, $options ) = @_;
	my $response;
	my $browser = LWP::UserAgent->new( agent => "Perl-Finance-CampBX" );
	if ($options){
		$response = $browser->post( $url, $options );
	}else{
		$response = $browser->post( $url );
	}
	if ($response->is_success) {
		my $content = $response->content; 
		my $json = new JSON;
		return $json->utf8->decode($content);
	} else {
		return 0;
	}    
} 

sub new {
	my $package = shift;
	return bless({}, $package);
}

1;
__END__


=head1 NAME

Finance::CampBX - Access to the CampBX bitcoin trading API

=head1 VERSION

version 0.2

=head1 SYNOPSIS

use Finance::CampBX;
my $campbx = new Finance::CampBX;

=head1 DESCRIPTION

Stub documentation for Finance::CampBX.

Note from the CampBX Website:
Please do not abuse the API interface with brute-forcing bots, and ensure
that there is at least 500 millisecond latency between two calls.
We may revoke the API access without notice for accounts violating this requirement.



=head2 Methods

=over 12


=item ticker

$campbx->ticker()

=item depth

$campbx->depth()

=item balance

$campbx->balance($userid, $password)
	Set $userid to your CampBX account user ID.
	Set $password to your CampBX account password.

=item orders

$campbx->orders($userid, $password)

=item margins

$campbx->margins($userid, $password)

=item getbtcaddress

$campbx->getbtcaddress($userid, $password)

=item quicktrade

$campbx->quicktrade($userid, $password, $trademode, $quantity, $price)
	Set $mode to 'QuickBuy' or 'QuickSell'.

=item cancelorder

$campbx->cancelorder($userid, $password, $type, $orderid)
	Set $type to 'Buy' or 'Sell'.

=item sendtobtc

$campbx->sendtobtc($userid, $password, $btcaddress, $btcamount)
	Set $btcaddress to valid recepient bitcoin address.

=item sendtoaccount

$campbx->sendtoaccount($userid, $password, $recepientid, $btcamount)
	Set $recepientid to valid recepient CampBX account ID.
	
=item new

Returns a new Finance::CampBX object

=item sendrequest

Used to send requests to CampBX

=back


=head1 SEE ALSO

https://campbx.com/api.php

=head1 AUTHOR

Rick Bragg, E<lt>rbragg@gmnet.netE<gt> www.GreenMountainNetwork.com 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Rick Bragg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
