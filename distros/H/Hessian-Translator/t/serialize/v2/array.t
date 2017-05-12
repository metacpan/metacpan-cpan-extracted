#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|t007.*|t017.*';

use Test::Hessian::V2::Serializer;
Test::Hessian::V2::Serializer->runtests();
