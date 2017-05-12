# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-04 16:35 (EST)
# Function: CER
#
# $Id: CER.pm,v 1.5 2007/03/06 02:50:10 jaw Exp $

package Encoding::BER::CER;
use Encoding::BER;
use vars qw($VERSION @ISA);
$VERSION = '1.00';
@ISA = qw(Encoding::BER);
use strict;

sub new {
    my $cl = shift;

    $cl->SUPER::new( @_, flavor => 'CER' );
}


# handle CER string disassembly x.690 9.2
sub rule_check_and_apply {
    my $me   = shift;
    my $data = shift;

    my $fl = $data->{flavor} || $me->{flavor};
    return unless $fl eq 'CER';
    my($tval, undef, $rule) = $me->ident_data_and_efunc($data->{type}, 'rule');
    return if $tval & 0x20;    # primitive only
    return unless $rule == 1;  # table in BER provides some support of this feature

    my $v = $data->{value};
    return unless length($v) > 1000;
    my @v;

    $me->debug('rule check: CER string disassembling');

    # convert long primitive string => constructed string of small chunks
    my $type = $data->{type};
    while( $v ){
	my $s = substr($v, 0, 1000, '');
	push @v, {
	    type  => $type,
	    value => $s,
	}
    }

    my @t = ((grep {$_ ne 'primitive'} (ref $type ? @$type : ($type))),
	     'constructed');
    
    {
	type  => \@t,
	value => \@v,
    };
}




=head1 NAME

Encoding::BER::CER - Perl module for encoding/decoding data using ASN.1 Canonical Encoding Rules (CER)

=head1 SYNOPSIS

  use Encoding::BER::CER;
  my $enc = Encoding::BER::CER->new();
  my $cer = $enc->encode( $data );
  my $xyz = $enc->decode( $cer );

=head1 BUGS

There are no known bugs in this module.
    
=head1 SEE ALSO

  Encoding::BER, Encoding::BER::DER

=head1 AUTHOR

Jeff Weisberg - http://www.tcp4me.com/

=cut
    ;


1;

