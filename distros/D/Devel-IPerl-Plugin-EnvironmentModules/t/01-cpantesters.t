use strict;
use warnings;
use Test::More;
use Devel::IPerl::Plugin::EnvironmentModules;

my $obj = new_ok('Devel::IPerl::Plugin::EnvironmentModules');

can_ok $obj, qw{register avail list list_array load search show unload};

done_testing;
