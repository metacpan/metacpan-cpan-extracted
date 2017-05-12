#!/usr/bin/perl
use strict;
use warnings;
use GStreamer -init;

# $Id$

my ($major, $minor, $micro) = GStreamer -> version();
printf "This program is linked against GStreamer %d.%d.%d\n",
       $major, $minor, $micro;
