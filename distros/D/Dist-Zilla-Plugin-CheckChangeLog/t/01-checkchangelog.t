# t/01-checkchangelog.t
use strict;
use warnings;
use Test::More 0.88;
use Test::Exception 0.43;
use Test::DZil;

# Default build, no args given to plugin, should pass
my $tzil0 = Builder->from_config(
    {dist_root => 'corpus/DZT-good-no-args'},
    {
        add_files => {
            'source/dist.ini' => simple_ini({}, 'GatherDir', [CheckChangeLog => {}]),
        }});

# Build with no args to plugin, should fail
my $tzil1 = Builder->from_config(
    {dist_root => 'corpus/DZT-bad-no-args'},
    {
        add_files => {
            'source/dist.ini' => simple_ini({}, 'GatherDir', [CheckChangeLog => {}]),
        }});

# Build with args to plugin, should pass
my $tzil2 = Builder->from_config(
    {dist_root => 'corpus/DZT-good-with-args'},
    {
        add_files => {
            'source/dist.ini' => simple_ini({}, 'GatherDir', [CheckChangeLog => {filename => 'Changes.pod'}]),
        }});

# Build with args to plugin, should fail
my $tzil3 = Builder->from_config(
    {dist_root => 'corpus/DZT-bad-with-args'},
    {
        add_files => {
            'source/dist.ini' => simple_ini({}, 'GatherDir', [CheckChangeLog => {filename => 'Changes.pod'}]),
        }});

# All test expects /Changes(?:pod)?/ to have ver 0.001

ok($tzil0->build);

dies_ok(sub { $tzil1->build }, 'expected to die');

ok($tzil2->build);

dies_ok(sub { $tzil3->build }, 'expecting to die');

done_testing;
