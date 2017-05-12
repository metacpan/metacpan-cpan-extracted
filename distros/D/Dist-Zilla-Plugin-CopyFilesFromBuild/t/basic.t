#!perl
use Test::Most;
use Test::Exception;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::CopyFilesFromBuild;
use Dist::Zilla::Plugin::ReadmeAnyFromPod;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                ['ReadmeAnyFromPod' => {
                    type => 'text',
                    # Just need somewhere other than the root
                    filename => 't/README.txt',
                    location => 'build',
                }],
                [ 'CopyFilesFromBuild' => {
                    copy => ['README', 't/basic.t', ],
                    move => ['t/README.txt'],
                } ],
            ),
        },
    }
);

lives_ok { $tzil->build; } "Built dist successfully";

my $content;

# Test copy README
$content = $tzil->slurp_file("build/README");
like($content, qr/README/, "Dist contains expected content in README");

$content = $tzil->slurp_file("source/README");
like($content, qr/README/, "Root contains expected content in README");

# Test copy file in subdir
$content = $tzil->slurp_file("build/t/basic.t");
like($content, qr/Test::More/, "Dist contains expected content in 't/basic.t'");

$content = $tzil->slurp_file("source/t/basic.t");
like($content, qr/Test::More/, "Root contains expected content in 't/basic.t'");

dies_ok {$content = $tzil->slurp_file("source/basic.t")} 'basic.t not present in root';

# Test move of generated file in subdir
dies_ok{ $content = $tzil->slurp_file("build/t/README.txt") } "'t/README.txt' not present in dist after moving";

dies_ok{ $content = $tzil->slurp_file("build/README.txt") } "README.txt not present in root";

$content = $tzil->slurp_file("source/t/README.txt");
like($content, qr/SYNOPSIS/, "Root contains expected content in 't/README.txt'");

done_testing();
