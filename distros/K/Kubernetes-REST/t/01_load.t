#!/usr/bin/env perl

use Test::More;

use_ok('Kubernetes::REST::Error');
use_ok('Kubernetes::REST::ListToRequest');
use_ok('Kubernetes::REST::HTTPTinyIO');

done_testing;
