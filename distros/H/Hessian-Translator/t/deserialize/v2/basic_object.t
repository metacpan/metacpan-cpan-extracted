#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

$ENV{TEST_METHOD} = 't006.*|t030.*|t031.*|t032.*|t033.*';

use Test::Hessian::V2::Deserializer;
Test::Hessian::V2::Deserializer->runtests();
