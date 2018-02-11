package main;

use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 't/lib';

my $iperl = new_ok('IPerl');

is $iperl->load_plugin('EnvironmentModules'), 1, 'loaded';

can_ok $iperl, qw{module_avail module_load module_list module_show module_unload};

my @modules = qw{this that another git something else entirely};

for my $name(qw{avail load list show unload}){
  my $cb = $iperl->can("module_$name");
  is $iperl->$cb(), -1, 'empty args == -1';
  is $iperl->$cb( $modules[int rand $#modules - 1] ), 1, 'returns 1';
}

done_testing;
