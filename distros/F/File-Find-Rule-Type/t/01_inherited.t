#!perl -w
use strict;
use Test::More tests => 1;

use lib './lib','../lib';

use File::Find::Rule::Type;
is_deeply( [ find( type => 'image/*', maxdepth => 1, in => 't' ) ],
           [ 't/happy-baby.JPG' ] );
