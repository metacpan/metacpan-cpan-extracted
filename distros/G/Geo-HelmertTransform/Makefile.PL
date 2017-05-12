#!/usr/bin/perl -w
#
# Makefile.PL:
# Generate makefile.
#
# Copyright (c) 2005 UK Citizens Online Democracy. All rights reserved.
# Email: chris@mysociety.org; WWW: http://www.mysociety.org/
#

my $rcsid = ''; $rcsid .= '$Id: Makefile.PL,v 1.1 2006-11-03 14:49:14 chris Exp $';

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Geo::HelmertTransform',
    VERSION_FROM    => 'lib/Geo/HelmertTransform.pm'
);
