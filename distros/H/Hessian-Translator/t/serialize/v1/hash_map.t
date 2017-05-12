#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't005.*|t006.*|t007.*|t020.*';

use Test::Hessian::V1::Serializer;
Test::Hessian::V1::Serializer->runtests();
