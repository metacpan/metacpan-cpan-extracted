#!/usr/bin/env perl

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Core modules
use_ok('Kubernetes::REST');
use_ok('Kubernetes::REST::Server');
use_ok('Kubernetes::REST::AuthToken');
use_ok('Kubernetes::REST::Kubeconfig');

# Internal modules
use_ok('Kubernetes::REST::Error');
use_ok('Kubernetes::REST::LWPIO');
use_ok('Kubernetes::REST::HTTPTinyIO');
use_ok('Kubernetes::REST::HTTPRequest');
use_ok('Kubernetes::REST::Role::IO');
use_ok('Kubernetes::REST::WatchEvent');
use_ok('Kubernetes::REST::LogEvent');
use_ok('Kubernetes::REST::CLI::Watch');

done_testing;
