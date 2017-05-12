# -*- perl -*-

# Copyright (c) 2007 by Jeff Weisberg
# Author: Jeff Weisberg <jaw+pause @ tcp4me.com>
# Created: 2007-Feb-10 16:42 (EST)
# Function: dumper test
#
# $Id: t3.t,v 1.3 2015/12/15 20:28:44 jaw Exp $

use lib 'lib';
use Encoding::BER::Dumper;
use strict;

print "1..5\n";
my $tno = 1;

my $b = pl2ber([
		0, 1, 2, 3,
		{ foo => 'a' },
		undef ]);

my $expect = '301802010002010102010202010363080403666f6f0401610500';

$expect =~ s/\s//gs;
$expect = pack('H*', $expect);

test( $expect eq $b);

my $d = ber2pl($b);

test( @$d == 6 );
test( $d->[2] == 2 );
test( $d->[4]{foo} eq 'a');
test( ! defined $d->[5] );

sub test {
    my $ok = shift;

    print(($ok ? "ok" : "not ok"), " ", $tno++, "\n");
}
