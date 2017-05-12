# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-05 19:51 (EST)
# Function: test
#
# $Id: t1.t,v 1.4 2007/02/10 22:09:32 jaw Exp $

use lib 'lib';
use Encoding::BER;


my @tests =
(
# [ encodedata, hexdump ]

 [ undef,     '05 00' ],
 [ 'public',  '04 06 70 75 62 6C 69 63' ],
 [ 0,         '02 01 00' ],
 [ 1,	      '02 01 01' ],
 [ 100,	      '02 01 64' ],
 [ 127,       '02 01 7F' ],
 [ 128,       '02 02 00 80' ],
 [ 200,	      '02 02 00 c8' ],
 [ 256,       '02 02 01 00' ],
 [ 1000,      '02 02 03 E8' ],
 [ 100000,    '02 03 01 86 A0' ],
 [ -1,        '02 01 FF' ],
 [ -128,      '02 01 80' ],
 [ -129,      '02 02 FF 7F' ],
 [ -200,      '02 02 FF 38' ],
 [ -100000,   '02 03 FE 79 60' ],
 [ 0xFFFFFFFF,'02 05 00 FF FF FF FF' ],

 [ { type => 'my_uint', value => '1'   }, 'C1 01 01' ],
 [ { type => 'my_uint', value => '2'   }, 'C1 01 02' ],
 [ { type => 'my_uint', value => '127' }, 'C1 01 7F' ],
 [ { type => 'my_uint', value => '128' }, 'C1 01 80' ],
 [ { type => 'my_uint', value => '255' }, 'C1 01 FF' ],
 [ { type => 'my_uint', value => '256' }, 'C1 02 01 00' ],

 [ { type => 'my_uint32', value => '1'   },  'C2 04 00 00 00 01' ],
 [ { type => 'my_uint32', value => '-1'   }, 'C2 04 FF FF FF FF' ],
 
 [ {type => 'bool', value => 0 }, '01 01 00' ],
 [ {type => 'bool', value => 1 }, '01 01 FF' ],

 [ {type => 'oid',  value => '1.3.6.1.2.37.9004.0' }, '06 08 2B    06 01 02 25 C6 2C 00' ],
 [ {type => 'roid', value => '1.3.6.1.2.37.9004.0' }, '0D 09 01 03 06 01 02 25 C6 2C 00' ],

 [ {type =>'bit_string',   value => "\xAA\x55\x01" }, '03 04 00 AA 55 01' ],
 [ {type => 'string',      value => 'foo' }, '04 03 66 6F 6F' ],
 [ {type => 'utf8_string', value => 'foo' }, '0C 03 66 6F 6F' ],
 
 # note: need supress warning from unknown type
 [ {type => ['universal', 'primitive', 4321], value => 'ab' }, '1F A1 61 02 61 62', [warn => sub{}] ],

 [ {type => ['constructed', 'string'], value => ['a','b','c','d'] },
   '24 0C 04 01 61 04 01 62 04 01 63 04 01 64' ],

 [ [1,1,1,1], '30 0C 02 01 01 02 01 01 02 01 01 02 01 01' ],
 [ [1,1,1,1], '30 80 02 01 01 02 01 01 02 01 01 02 01 01 00 00', [flavor=>'CER'] ],
 
 );

# only test floating point if POSIX is available
eval {
    require POSIX;
    push @tests, (
		  [ 0.25,      '09 03 80 FE 01', [flavor => 'DER'] ],
		  [ 0.5,       '09 03 80 FF 01', [flavor => 'DER'] ],
		  [ 1/8192,    '09 03 80 F3 01', [flavor => 'DER'] ],
		  [ {type => 'real', value => 1 }, '09 03 80 00 01', [flavor => 'DER'] ],
		  [ {type => 'real', value => 2 }, '09 03 80 01 01', [flavor => 'DER'] ],
		  [ {type => 'real', value => 3 }, '09 03 80 00 03', [flavor => 'DER'] ],
		  );
};

# only if BigInt is available
eval {
    require Math::BigInt;
    push @tests, map {
	[ Math::BigInt->new($_->[0]), $_->[1] , $_->[2] ]
	} (
	   [ '1',   '02 01 01' ],
	   [ '2',   '02 01 02' ],
	   [ '127', '02 01 7F' ],
	   [ '128', '02 02 00 80' ],
	   [ '129', '02 02 00 81' ],
	   [ '255', '02 02 00 FF' ],
	   [ '256', '02 02 01 00' ],
	   [ '257', '02 02 01 01' ],
	   
	   [ '-1', '02 01 FF' ],
	   [ '-2', '02 01 FE' ],
	   [ '-128', '02 01 80' ],
	   [ '-129', '02 02 FF 7F' ],
	   [ '-255', '02 02 FF 01' ],
	   [ '-256', '02 02 FF 00' ],
	   [ '-257', '02 02 FE FF' ],
	   
	   [ '0x123412341234', '02 06 12 34 12 34 12 34' ],
	   [ '0x12341234123',  '02 06 01 23 41 23 41 23' ],
	   [ '0x823482348234', '02 07 00 82 34 82 34 82 34' ],
	   ['-0x823482348234', '02 07 FF 7D CB 7D CB 7D CC' ],

	   [ '1111222233334444555566667777888899990000',
	    '02 11 03 43 FD 9E 0E 3D 21 4B CE 86 4F A0 8B 98 B6 81 F0' ],
	   ['-1111222233334444555566667777888899990000',
	    '02 11 FC BC 02 61 F1 C2  DE B4 31 79 B0 5F 74 67 49 7E 10' ],
	   
	   );
    push @tests, map {
	[ { type => 'my_uint', value => Math::BigInt->new($_->[0]) }, $_->[1] , $_->[2] ]
	} (
	   [ '1',   'C1 01 01' ],
	   [ '2',   'C1 01 02' ],
	   [ '127', 'C1 01 7F' ],
	   [ '128', 'C1 01 80' ],
	   [ '255', 'C1 01 FF' ],
	   [ '256', 'C1 02 01 00' ],
	   
	   );
	

    
};



print "1..", scalar(@tests), "\n";
my $testno = 0;
foreach (@tests){
    test( @{$_} );
}

sub test {
    my( $enc, $hex, $opts ) = @_;

    $opts ||= [];
    my $ber = Encoding::BER->new( @$opts );
    $ber->add_implicit_tag('private', 'primitive', 'my_uint',   1, 'uint');
    $ber->add_implicit_tag('private', 'primitive', 'my_uint32', 2, 'uint32');
    my $res = $ber->encode( $enc );

    unless( $hex ){
        Encoding::BER::hexdump($res);
	return;
    }
    
    $hex =~ s/\s//gs;
    $hex = pack('H*', $hex);
    $ok = $res eq $hex;
    
    $testno ++;
    if( $ok ){
        print "ok $testno\n";
    }else{
        print "not ok $testno\n";
    }
}
