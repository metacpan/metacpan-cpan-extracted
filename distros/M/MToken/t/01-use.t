#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 43 2017-07-31 13:04:58Z minus $
#
#########################################################################
use Test::More tests => 2;
use lib qw(inc);
BEGIN { use_ok('MToken') };
use FakeCTK;
ok(MToken::void(),'MToken::void()');
1;
