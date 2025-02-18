#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::CleanNamespaces';

Test::CleanNamespaces->all_namespaces_clean();
