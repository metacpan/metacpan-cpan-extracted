#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|t019.*';

use Test::Hessian::V1::Deserializer;
Test::Hessian::V1::Deserializer->runtests();
