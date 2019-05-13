#!/usr/bin/perl
# $Id: snmp.pl,v 1.4 2012/01/14 10:33:30 dk Exp $
use strict;
use SNMP;
use IO::Lambda::SNMP qw(:all);
use IO::Lambda qw(:lambda);

my $sess = SNMP::Session-> new(
	DestHost => 'localhost',
	Community => 'public',
	Version   => '2c',
);

this lambda {
	context $sess, new SNMP::Varbind;
	snmpgetnext {
		my $vb = shift;

		# check success
		return unless $vb;
		return if $sess-> {ErrorNum};
		return if $vb->[0]->[2] eq 'ENDOFMIBVIEW';

		# print and resubmit
		print "@{$vb->[0]}\n" ; 
		context $sess, $vb;
		again;
	};
};
this-> wait;
