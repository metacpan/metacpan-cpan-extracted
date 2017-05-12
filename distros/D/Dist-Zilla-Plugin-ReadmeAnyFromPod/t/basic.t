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
            ),
        },
    }
);

lives_ok { $tzil->build; } "Built dist successfully";

my $content = $tzil->slurp_file("build/README");
like($content, qr/\S/, "Dist contains non-empty README");

done_testing();
