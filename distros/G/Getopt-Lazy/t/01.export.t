use Test::More tests => 1;

BEGIN{
use strict;
use warnings;
use Getopt::Lazy;
}

can_ok('main', qw(GetOptions show_help)) or 
    diag("Testing exported functions");
