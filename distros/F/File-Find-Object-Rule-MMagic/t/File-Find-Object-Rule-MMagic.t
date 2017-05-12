#!perl

use strict;
use warnings;

use Test::More tests => 1;

use File::Find::Object::Rule::MMagic;
use File::Spec;

# TEST
is_deeply( [ find( magic => 'image/*', maxdepth => 2, in => 't' ) ],
           [ File::Spec->catfile(File::Spec->curdir(), "t", "happy-baby.JPG")]
           );
