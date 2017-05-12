use strict;
use warnings;

use autobox::Core 1.24;

use Test::More;
use File::Temp 'tempdir';
use Test::DZil;

use lib 't/lib';

my $STASH_NAME = '%TestStash';
my @dist_ini   = qw(TestAddStash FakeRelease);
my $dist_root  = tempdir CLEANUP => 1;

my $tzil = Builder->from_config(
    { dist_root => "$dist_root" },
    {
        add_files => {
            'source/dist.ini' => simple_ini(@dist_ini),
        },
    },
);

isa_ok $tzil, 'Dist::Zilla::Dist::Builder';
ok $tzil->plugin_named('TestAddStash'), 'tzil has our test plugin';

dump_stash_names($tzil);

ok !$tzil->stash_named($STASH_NAME), 'tzil does not yet have the stash';
$tzil->release;
my $stash = $tzil->stash_named($STASH_NAME);
isa_ok $stash, 'Dist::Zilla::Stash::TestStash';

dump_stash_names($tzil);

sub dump_stash_names {
    my $tzil = shift @_;

    note 'global stashes: ' . $tzil->_global_stashes->keys->sort->join(', ');
    note 'local stashes:  ' . $tzil->_local_stashes->keys->sort->join(', ');

    return;
}

done_testing;
