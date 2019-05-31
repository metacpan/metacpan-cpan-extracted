#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-new.t 4 2019-05-28 10:57:50Z minus $
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
