#!/usr/bin/env perl
#
# This file is part of Dist-Zilla-PluginBundle-RSRCHBOY
#
# This software is Copyright (c) 2018, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use Test::More tests => 1;

BEGIN { use_ok 'Dist::Zilla::PluginBundle::RSRCHBOY' }

diag("Testing Dist::Zilla::PluginBundle::RSRCHBOY $Dist::Zilla::PluginBundle::RSRCHBOY::VERSION, Perl $], $^X");
