use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

{
    throws_ok {
        Builder->from_config(
            { dist_root => 'corpus/dist/DZT' },
            {
                add_files => {
                    'source/dist.ini' => simple_ini(
                        'GatherDir',
                        [ 'ReadmeAnyFromPod' => { location => 'build', phase => 'release' } ],
                    ),
                },
            }
        );
    }
    qr/\[ReadmeAnyFromPod\] You cannot use location=build with phase=release!/,
    "plugin dies on incompatible config combination";
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [ 'ReadmeAnyFromPod' => { location => 'root', phase => 'release' } ],
                    [ 'FakeRelease' ],
                ),
            },
        }
    );

    lives_ok { $tzil->build; } "Built dist successfully";

    ok !-e "build/README", "README has not been created in the build";
    ok !-e "source/README", "README has not been created yet";

    lives_ok { $tzil->release; } "released dist successfully";

    ok !-e "build/README", "README has not been created in the build";

    my $content = $tzil->slurp_file("source/README");
    like($content, qr/\S/, "Dist contains non-empty README");
}

done_testing();
