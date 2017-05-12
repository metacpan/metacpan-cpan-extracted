#!/usr/local/bin/perl
#################################################################
#
#   $Id: 08_test_program_name.t,v 1.2 2005/11/07 16:49:09 erwan Exp $
#
#   050919 erwan Created
#   051007 erwan Fix dependencies
#   

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;
use lib ("./t/", "../lib/", "./lib/");

BEGIN {
    use_ok('Log::Localized');
}

is(Log::Localized::_test_program,"08_test_program_name.t","test program name properly identified");
