# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-04 16:43 (EST)
# Function: dump perl data to/from ber
#
# $Id: Dumper.pm,v 1.5 2007/03/06 02:50:10 jaw Exp $

package Encoding::BER::Dumper;
use Encoding::BER;
use vars qw($VERSION);
$VERSION = '1.00';
use strict;

sub pl2ber {
    my $pl = shift;

    my $enc = Encoding::BER->new(acanonical => 1);
    $enc->encode($pl);
}

sub ber2pl {
    my $ber = shift;
    
    my $dec = Encoding::BER->new( );
    $dec->add_tag('application', 'constructed', 'berdump_hash', 3);
    decanon($dec->decode($ber));
}

sub decanon {
    my $n = shift;
    my $v = $n->{value};

    return $v unless ref $v;

    my @v;
    for my $r (@$v){
	push @v, decanon($r);
    }

    if( $n->{type}[2] eq 'berdump_hash' ){
	return { @v };
    }else{
	return \@v;
    }
}

sub import {
    my $pkg    = shift;
    my $caller = caller;

    for my $f ('pl2ber', 'ber2pl'){
	no strict;
	my $fnc = $pkg->can($f);
	next unless $fnc;
	*{$caller . '::' . $f} = $fnc;
    }
}

=head1 NAME

Encoding::BER::Dumper - Perl module for dumping Perl objects from/to BER

=head1 SYNOPSIS

  use Encoding::BER::Dumper;

  $ber  = pl2ber( $perl );
  $perl = ber2pl( $ber );

=head1 DESCRIPTION


=head1 EXPORTS

The following methods are exported:

  ber2pl, pl2ber

=head1 BUGS

Not all types of things perl can be encoded in BER.

=head1 SEE ALSO

  Yellowstone National Park.
  Encoding::BER, Data::Dumper, XML::Dumper

=head1 AUTHOR

Jeff Weisberg - http://www.tcp4me.com/

=cut
    ;
    

1;
