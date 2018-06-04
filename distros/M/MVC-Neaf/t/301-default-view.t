#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

get '/' => sub { +{foo => 42 } };
is neaf->run_test('/'), '{"foo":42}', "Render as json by default";

done_testing;
