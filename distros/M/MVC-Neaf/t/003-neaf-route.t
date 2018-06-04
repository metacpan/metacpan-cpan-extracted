#!perl -T

use warnings;
use strict;
use Test::More tests => 1;

my $sub = eval {
    require MVC::Neaf;
    my $n = MVC::Neaf->new;
    $n->route( '/' => sub {+{}} );
    $n->run;
};

diag $@ if $@;

is (ref $sub, 'CODE', "run works") || print "Bail out!\n";
