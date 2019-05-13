#! /usr/bin/perl
# $Id: 06_stream.t,v 1.2 2008/12/21 10:07:28 dk Exp $

use strict;
use warnings;
use Time::HiRes qw(time);
use Test::More tests => 5;
use IO::Lambda qw(:all);

my $reader = lambda {
	my ( $fh, $buf, $len) = @_;

	my $max = length($$fh);
	my $ofs = pos($$fh) || 0;

	return undef, 'eof' if $ofs >= $max;

	$len = $max - $ofs if $len > $max - $ofs;
	$$buf .= substr( $$fh, $ofs, $len);
	pos($$fh) = $ofs + $len;

	return $len;
};

my $wrcount = 0;
my $writer_cb;
my $writer = lambda {
	my ( $fh, $buf, $len, $ofs) = @_;

	$writer_cb->() if $writer_cb;

	return 0 if $len < 1;
	$len = 1; # write only 1 byte at a time 

	$wrcount++;

	my $data = substr( $$buf, $ofs, $len);
	my $o    = pos($$fh) || 0;
	substr( $$fh, $o, $len) = $data;
	pos($$fh) = $o + $len;
	return $len;
};

my $fh = \ "hello world";
my $buf;

# readbuf
this readbuf($reader);
ok( "hello " eq  this-> wait( $fh, \$buf, qr/.*?\s/ ), 'readbuf');

this lambda {
	$buf =~ s/.*?\s//;
	context readbuf($reader), $fh, \$buf, qr/d$/;
	tail { shift || '' }
};
ok(( 'd' eq this-> wait), 'readbuf wrapped' );


this lambda {
	context readbuf($reader), $fh, \$buf;
	tail { shift; shift }
};
ok(( 'eof' eq this-> wait), 'readbuf eof' );

# writebuf
$fh  = \(my $str = "");
$buf = "hello world";
this writebuf($writer);
this-> wait( $fh, \$buf);
ok( length($buf) == $wrcount, 'writebuf');

# undef length writebuf
$buf = "1";
$writer_cb = sub {
	$buf .= "2";
	$writer_cb = undef;
};
$wrcount = 0;
this writebuf($writer);
this-> wait( $fh, \$buf);
ok(( $buf eq '12' and length($buf) == $wrcount), 'dynamic writebuf');
