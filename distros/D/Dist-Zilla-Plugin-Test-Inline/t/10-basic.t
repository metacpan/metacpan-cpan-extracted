#!perl

# Code taken from tests in Dist::Zilla::Plugin::ReadmeAnyFromPod

use Test::More;
use Test::Exception;

use strict;
use warnings;
 
use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::Test::Inline;

my $tzil = Builder->from_config(
    { dist_root => 't/TestProject' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                [ 'GatherDir' => MyExcludes => { exclude_match => [ 'Dontprocess\.pm' ] } ],
                [ 'Test::Inline' ],
            ),
        },
    }
);

lives_ok { $tzil->build; } "Built dist successfully";
 
my $content = $tzil->slurp_file("build/t/inline-tests/test_project.t");
like $content, qr/^use Test::Simple => 1;\nok\(1 != 2, "1 does not equal 2"\);/m,
  "Correctly extract inline tests";

ok ! -f $tzil->tempdir->file("build/t/inline-tests/test_dontprocess.t"),
  "Do not process file excluded by file gatherer";

ok ! -f $tzil->tempdir->file("build/t/inline-tests/externalthing.t"),
  "Do not process file outside lib/";

done_testing();
