#! perl

# $Id: 92_ivp_postgres.t,v 1.1 2009/10/15 16:27:04 jv Exp $  -*-perl-*-

use strict;
use warnings;

our $dbdriver = "postgres";

if ( !$dbdriver && $0 =~ /\d+_ivp_(.+).t/ ) {
    $dbdriver = $1;
}

chdir("t") if -d "t";

$ENV{LANG} = "nl_NL";
require "90_ivp_common.pl";

