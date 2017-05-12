#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                [ 'ReadmeAnyFromPod', 'ReadmeTextInBuild' ],
                [ 'PruneFiles', { filename => [ "README" ], }, ],
            ),
        },
    }
);

throws_ok { $tzil->build; } qr/Could not find a README file during the build/,
  'pruning generated README is fatal';

done_testing();
