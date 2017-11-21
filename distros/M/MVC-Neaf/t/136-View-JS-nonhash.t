#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::View::JS;

my $js = MVC::Neaf::View::JS->new;

is [$js->render( { -serial => undef } )]->[0], 'null', "undef ok";
is [$js->render( { -serial => [3,4,5] } )]->[0], '[3,4,5]', "array ok";

done_testing
