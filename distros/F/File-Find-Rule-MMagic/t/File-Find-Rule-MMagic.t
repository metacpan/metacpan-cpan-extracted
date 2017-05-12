#!perl -w
use strict;
use Test::More tests => 1;

use File::Find::Rule::MMagic;
is_deeply( [ find( magic => 'image/*', maxdepth => 2, in => 't' ) ],
           [ 't/happy-baby.JPG' ] );
