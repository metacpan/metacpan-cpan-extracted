use strict;
use warnings;
use Test::More;
use Module::Find;

my $module = 'Dist::Zilla::PluginBundle::BerryGenomics';
use_ok($_) foreach findallmod $module;
use_ok($module);
done_testing;

