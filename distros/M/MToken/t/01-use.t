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
# $Id: 01-use.t 58 2019-06-06 19:30:00Z minus $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('MToken') };
ok(MToken->VERSION,'MToken version');
1;
