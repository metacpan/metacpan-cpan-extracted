#!/usr/bin/env perl

use strict;
use warnings;

#########################
# GtkStatusbar Tests
# 	- rm
#########################

#########################

use Gtk2::TestHelper tests => 10, noinit => 1;

ok( my $sts = Gtk2::Statusbar->new );

$sts->set_has_resize_grip(1);
is( $sts->get_has_resize_grip, 1 );

ok( my $sts_cid1 = $sts->get_context_id('Main') );
ok( $sts->push($sts_cid1, 'Ready 1-0') );
ok( $sts->push($sts_cid1, 'Ready 1-1') );

ok( my $sts_cid2 = $sts->get_context_id('Not Main') );
ok( my $sts_mid1 = $sts->push($sts_cid2, 'Ready 2-0') );
ok( $sts->push($sts_cid2, 'Ready 2-1') );

$sts->pop($sts_cid2);
$sts->pop($sts_cid1);

$sts->pop($sts_cid2);
$sts->remove($sts_cid2, $sts_mid1);

SKIP: {
	skip 'new 2.20 stuff', 1
		unless Gtk2->CHECK_VERSION(2, 20, 0);

	isa_ok ($sts->get_message_area, 'Gtk2::Widget');
}

SKIP: {
	skip 'new 2.22 stuff', 0
		unless Gtk2->CHECK_VERSION(2, 22, 0);

	$sts->remove_all ($sts_cid1);
}

ok(1);

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
