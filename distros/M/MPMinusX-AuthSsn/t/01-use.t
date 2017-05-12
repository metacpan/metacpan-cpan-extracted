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
# $Id: 01-use.t 2 2013-08-07 09:50:14Z minus $
#
#########################################################################
use Test::More tests => 1;
use lib qw(inc);
use Test::MPMinus;
BEGIN { use_ok('MPMinusX::AuthSsn') };
1;
