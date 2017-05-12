#!perl -T
#===============================================================================
#
#         FILE:  pod-coverage.t
#
#  DESCRIPTION:  testing POD coverage
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr.-Ing. Fritz Mehner (Mn), <mehner@fh-swf.de>
#      COMPANY:  Fachhochschule Südwestfalen, Iserlohn
#      VERSION:  1.0
#      CREATED:  30.05.2007 13:50:02 CEST
#     REVISION:  $Id: pod-coverage.t,v 1.1.1.1 2007/05/30 12:05:03 mehner Exp $
#===============================================================================

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my $login;
eval { $login = $ENV{USER} };
plan skip_all => "Only the author needs to check the POD documentation." if ($@ || $login ne "mehner" );

all_pod_coverage_ok();
