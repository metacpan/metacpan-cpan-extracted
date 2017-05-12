#!/usr/bin/env perl

# Copyright (C) 2008  Joshua Hoblitt
# 
# $Id: 01_load.t,v 1.2 2008/09/30 03:35:51 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib ./t );

use Test::More tests => 1;

BEGIN { use_ok( 'File::Mountpoint' ); }
