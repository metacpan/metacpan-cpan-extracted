use strict;
use warnings;

use autobox::Core 1.24;

use Test::More;
use File::Temp 'tempdir';
use Test::DZil;

use lib 't/lib';

my $STASH_NAME = '%TestStash';
my @dist_ini   = ($STASH_NAME, 'FakeRelease');
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
ok !!$tzil->stash_named($STASH_NAME), "$STASH_NAME exists, as it expected";

done_testing;
