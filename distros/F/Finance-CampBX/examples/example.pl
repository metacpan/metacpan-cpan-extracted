#!/usr/bin/perl
# Copyright (c) 2012 Rick Bragg <rbragg@gmnet.net> www.GreenMountainNetwork.com 
use strict;
use warnings;

use Finance::CampBX;

my $userid = ''; #Set to your CampBX account user ID.
my $password = ''; #Set to your CampBX account password.
my ($mode, $quantity, $price, $type, $orderid, $btcaddress, $btcamount, $recepientid);

my $campbx = new Finance::CampBX;
my $out;


$out = "Ticker: \n";
my $ticker = $campbx->ticker();
foreach my $k (keys %{$ticker}) {
	$out .= "  $k - ".${$ticker}{$k}."\n"
}  	
$out .= "\n";
print $out;


$out = "Market Depth: \n";
my $depth = $campbx->depth();
foreach my $k (keys %{$depth}) {
	$out .= "  $k: \n";
	foreach my $element ( @{${$depth}{$k}} ) { 
		$out .= "    - @{$element} \n";
	} 
	$out .= "\n";
}  
print $out;


$out = "My Balance: \n";
my $balance = $campbx->balance( $userid, $password );
foreach my $k (keys %{$balance}) {
	$out .=  "  $k - ".${$balance}{$k}."\n";
}  
$out .= "\n";
print $out;


$out = "My Orders: \n";
my $orders = $campbx->orders( $userid, $password );
foreach my $k (keys %{$orders}) {
	if($k eq 'Error'){
		$out = "  $k - ".${$depth}{$k}."\n"
	}else{
		$out .= "  $k: \n";
		foreach my $element ( @{${$orders}{$k}} ) { 
			foreach my $h ( keys %{$element} ) { 
				$out .=  "    - ".${$element}{$h}." \n";
			}
		} 
		$out .= "\n";
	}
}  
print $out;


$out = "My Margins: \n";
my $margins = $campbx->margins( $userid, $password );
foreach my $k (keys %{$margins}) {
	if($k eq 'Error'){
		$out = "  $k - ".${$depth}{$k}."\n"
	}else{
		$out .= "  $k: \n";
		foreach my $element ( @{${$margins}{$k}} ) { 
			foreach my $h ( keys %{$element} ) { 
				$out .=  "    - ".${$element}{$h}." \n";
			}
		} 
		$out .= "\n";
	}
} 
print $out;


$out = "New Bitcoin Address: \n";
my $getbtcaddress = $campbx->getbtcaddress( $userid, $password );
foreach my $k (keys %{$getbtcaddress}) {
	$out .= "  $k - ".${$getbtcaddress}{$k}."\n";
}  
$out .= "\n";
print $out;


$out = "Quick Trade: \n";
$mode = 'QuickBuy'; #Set to 'QuickBuy' or 'QuickSell'.
$quantity = 0;
$price = 0;
my $quicktrade = $campbx->quicktrade( $userid, $password, $mode, $quantity, $price );
foreach my $k (keys %{$quicktrade}) {
	$out .= "  $k - ".${$quicktrade}{$k}."\n";
}  
$out .= "\n";
print $out;


$out = "Cancel Order: \n";
$type = 'Buy'; #Set to 'Buy' or 'Sell'.
$orderid = 0;
my $cancelorder = $campbx->cancelorder( $userid, $password, $type, $orderid );
foreach my $k (keys %{$cancelorder}) {
	$out .= "  $k - ".${$cancelorder}{$k}."\n";
}  
$out .= "\n";
print $out;


$out = "Send Coins: \n";
$btcaddress = 'test'; #Set to valid recepient bitcoin address.
$btcamount = 0;
my $sendtobtc = $campbx->sendtobtc( $userid, $password, $btcaddress, $btcamount );
foreach my $k (keys %{$sendtobtc}) {
	$out .= "  $k - ".${$sendtobtc}{$k}."\n";
}  
$out .= "\n";
print $out;



