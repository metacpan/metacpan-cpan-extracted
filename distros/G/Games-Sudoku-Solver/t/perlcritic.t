#!perl 
#===============================================================================
#
#         FILE:  perlcritic.t
#
#  DESCRIPTION:  testing PBP compliance
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr.-Ing. Fritz Mehner (Mn), <mehner@fh-swf.de>
#      COMPANY:  Fachhochschule Südwestfalen, Iserlohn
#      VERSION:  1.0
#      CREATED:  30.05.2007 13:48:15 CEST
#     REVISION:  $Id: perlcritic.t,v 1.1.1.1 2007/05/30 12:05:03 mehner Exp $
#===============================================================================

use strict;
use warnings;

if (!require Test::Perl::Critic) {
    Test::More::plan(
        skip_all => "Test::Perl::Critic required for testing PBP compliance"
    );
}

use Test::More;
my $login;
eval { $login = $ENV{USER} };
plan skip_all => "Only the author needs to check the module for PBP compliance." if ($@ || $login ne "mehner" );

Test::Perl::Critic::all_critic_ok();
