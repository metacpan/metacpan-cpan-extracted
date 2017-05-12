# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-04 15:51 (EST)
# Function: BER Encoding/Decoding for SNMP
#
# $Id: SNMP.pm,v 1.7 2007/03/06 02:50:11 jaw Exp $

package Encoding::BER::SNMP;
use Encoding::BER 'init_tag_lookups';
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(Encoding::BER);
use strict;

			     
my %TAG =
(
 application => {
     ip_address	      => { v => 0,   type => ['application'], e => \&encode_ip,    d => \&decode_ip },
     counter32	      => { v => 1,   type => ['application'], implicit => 'uint32'    },
     gauge32	      => { v => 2,   type => ['application'], implicit => 'uint32'    },
     timeticks	      => { v => 3,   type => ['application'], implicit => 'int32'     },
     opaque	      => { v => 4,   type => ['application'], implicit => 'octet_string'        },
     counter64	      => { v => 6,   type => ['application'], implicit => 'unsigned_integer'    },
 },
 context => {
     get_request      => { v => 0,   type => ['context', 'constructed'], implicit => 'sequence' },
     get_next_request => { v => 1,   type => ['context', 'constructed'], implicit => 'sequence' },
     get_response     => { v => 2,   type => ['context', 'constructed'], implicit => 'sequence' },
     set_request      => { v => 3,   type => ['context', 'constructed'], implicit => 'sequence' },
     trap	      => { v => 4,   type => ['context', 'constructed'], implicit => 'sequence' },
     get_bulk_request => { v => 5,   type => ['context', 'constructed'], implicit => 'sequence' },
     inform_request   => { v => 6,   type => ['context', 'constructed'], implicit => 'sequence' },
     snmpv2_trap      => { v => 7,   type => ['context', 'constructed'], implicit => 'sequence' },
     report           => { v => 8,   type => ['context', 'constructed'], implicit => 'sequence' },
 },
 );

my %ALLTAG;
my %REVTAG;

init_tag_lookups( \%TAG, \%ALLTAG, \%REVTAG );


sub subclass_tag_data_byname {
    my $me    = shift;
    my $name  = shift;

    $ALLTAG{$name};
}

sub subclass_tag_data_bynumber {
    my $me    = shift;
    my $class = shift;
    my $tnum  = shift;

    $TAG{$class}{ $REVTAG{$class}{$tnum} };
}

sub encode_ip {
    my $me   = shift;
    my $data = shift;
    my $val  = $data->{value};
    # either dotted-quad or 4B-packed

    if( length($val) == 4){
	$val;
    }else{
	my @o = split /\./, $val;
	$me->error("invalid IP address: $val") unless @o == 4;
	pack('C4', @o);
    }
}

sub decode_ip {
    my $me   = shift;
    my $data = shift;
    my $type = shift;

    $me->warn("received invalid IP address") unless length($data) == 4;

    {
	value => join('.', unpack('C4', $data)),
    };
}

=head1 NAME

Encoding::BER::SNMP - adds SNMP specific tags to Encoding::BER

=head1 SYNOPSIS

  use Encoding::BER::SNMP;
  my $enc  = Encoding::BER::SNMP->new();
  my $snmp = $enc->encode( [ 1, 'public',
			     { type  => 'get_request',
		               value => [ $reqid, 0, 0, 
					  [ [ { type  => 'oid',
						value => '1.3.6.1.2.1.2.2.1.10.4' },
					      undef ] ] ] };
  send(UDP, $snmp, 0);
		     
=head1 DESCRIPTION

This is a subclass of Encoding::BER, and the following tags are made available:

  ip_address counter32 gauge32 timeticks opaque counter64
  get_request get_next_request get_response set_request
  trap get_bulk_request inform_request snmpv2_trap report

=head1 BUGS

There are no known bugs in this module.
    
=head1 SEE ALSO

  Encoding::BER

=head1 AUTHOR

Jeff Weisberg - http://www.tcp4me.com/

=cut
    ;




1;
