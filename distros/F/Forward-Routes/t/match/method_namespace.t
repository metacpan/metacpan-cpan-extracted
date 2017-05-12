use strict;
use warnings;
use Test::More tests => 6;

use Forward::Routes;


#############################################################################
### method tests

my $m = Forward::Routes::Match->new;

is $m->namespace, undef;

is $m->_set_namespace('Hello::World'), $m;
is $m->namespace, 'Hello::World';

is $m->_set_namespace('Hi::World'), $m;
is $m->namespace, 'Hi::World';

is $m->namespace('Hello::World'), 'Hi::World';

