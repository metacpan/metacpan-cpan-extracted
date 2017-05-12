#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|.*test_long.*';

use Test::Hessian::V2::Deserializer;
Test::Hessian::V2::Deserializer->runtests();
