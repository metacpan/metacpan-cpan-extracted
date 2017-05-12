#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{ ./t/lib };

use Contextual::Return;

use Test::Hessian::Service::V1;
Test::Hessian::Service::V1->runtests();
