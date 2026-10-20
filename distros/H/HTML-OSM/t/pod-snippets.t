#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Pod::Snippets';

# testgroup => 1 needs Test::Group; check at run time so 'perl -c' still passes
test_needs 'Test::Group';

my @modules = qw/ HTML::OSM /;
Test::Pod::Snippets->import();
Test::Pod::Snippets->new()->runtest(module => $_, testgroup => 1) for @modules;

done_testing();
