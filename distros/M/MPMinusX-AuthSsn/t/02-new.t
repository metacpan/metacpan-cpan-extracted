#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-new.t 2 2013-08-07 09:50:14Z minus $
#
#########################################################################
use Test::More tests => 5;
use lib qw(inc);
use Test::MPMinus;
use MPMinusX::AuthSsn;
my $m = new_ok( 'Test::MPMinus' );
ok(1,"Start");
is(lc($m->t), "ok", "Test method: t()");
my $usid = undef;
my $ssn = new_ok ( 'MPMinusX::AuthSsn' => [ $m, $usid ] );
ok(1,"Finish");
1;
