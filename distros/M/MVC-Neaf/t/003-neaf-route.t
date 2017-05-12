#!perl -T

use warnings;
use strict;
use Test::More tests => 1;

my $sub = eval {
    require MVC::Neaf;
    MVC::Neaf->route( '/' => sub {+{}} );
    MVC::Neaf->run;
};

is (ref $sub, 'CODE', "run works") || print "Bail out!\n";
