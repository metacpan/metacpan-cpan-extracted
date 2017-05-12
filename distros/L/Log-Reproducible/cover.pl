#!/usr/bin/env perl
# Mike Covington
# created: 2014-04-04
#
# Description:
#
use strict;
use warnings;

# $ENV{DEVEL_COVER_OPTIONS} = "-ignore,Build";     # From Module::Build docs
# $ENV{DEVEL_COVER_OPTIONS} = "-ignore,perl5lib";  # From Gabor Szabo's workshop
system("./Build.pl");
system("./Build testcover");
