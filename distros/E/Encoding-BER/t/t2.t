# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-05 19:51 (EST)
# Function: floating point tests
#
# $Id: t2.t,v 1.2 2007/02/10 22:09:32 jaw Exp $

use lib 'lib';
use Encoding::BER::DER;

my @tests =
(
   1,	-1,
   2,	-2,
   3,	-3,
   .5,	-.5,
   .125, -.125,
   3.1,	-3.1,
   0.9,  -0.9,
   .0000000001,
   1000000.000001,
   1234567.7654321,
   1.1e23,
   1.1e43,
   1.1e63,
   1.1e-23,
   1.1e-43,
   1.1e-63,
);

print "1..", scalar(@tests), "\n";
my $testno = 0;
foreach (@tests){
    test( $_ );
}

sub test {
    my( $num ) = @_;

    my $ber = Encoding::BER::DER->new( );
    my $res = $ber->decode($ber->encode( { type => 'real', value => $num } ));
    $res = $res->{value};
    
    $ok = $res == $num;

    unless( $ok ){
	# allow some roundoff error

	my $d = abs( ($res - $num) / $num );
	
	$ok = 1 if $d < 0.00001;
    }
    
    
    $testno ++;
    if( $ok ){
        print "ok $testno\n";
    }else{
        print "not ok $testno\t$res\n";
    }
}
