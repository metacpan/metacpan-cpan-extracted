#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Pod::LinkCheck';

Test::Pod::LinkCheck->import();
Test::Pod::LinkCheck->new->all_pod_ok();
