#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Pod::Snippets';

my @modules = qw/ HTML::D3 /;
Test::Pod::Snippets->import();
Test::Pod::Snippets->new()->runtest(module => $_, testgroup => 1) for @modules;

done_testing();
