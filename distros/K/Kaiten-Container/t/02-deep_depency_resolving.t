#! /usr/bin/env perl

use v5.10;
use warnings;

use lib::abs qw(./lib);


# load all the test classes I want to run
use Kaiten::Container::TestDeepDependency;

# and run them all
Test::Class->runtests;