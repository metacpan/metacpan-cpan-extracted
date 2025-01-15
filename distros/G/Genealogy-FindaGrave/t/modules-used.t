#!perl -w

use strict;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Module::Used';

my $used = Test::Module::Used->new(meta_file => 'MYMETA.yml');
$used->ok();
