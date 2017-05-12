#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

my @content_tests = (
    [ qr/^# SYNOPSIS\s*$/m, "Markdown header" ],
    [ qr/([_*]{2})[^\s_*]+\1/, "Markdown bold formatting" ],
    [ qr/(?<!_)_[^\s_]+_(?!_)|(?<!\*)\*[^\s*]+\*(?!\*)/, "Markdown italic formatting" ],
);

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini('GatherDir', 'ReadmeMarkdownFromPod')
        },
    }
);

SKIP: {
    lives_ok { $tzil->build; } "dist builds successfully"
        or skip "Build failed", scalar @content_tests + 1;
    my $readme_content = eval { $tzil->slurp_file("build/README.mkdn"); };
    ok $readme_content, "dist contains README.mkdn file"
        or skip "Missing README.mkdn file", scalar @content_tests;

    for my $test (@content_tests) {
        my ($regex, $desc) = @$test;
        my $message = "Markdown readme file contains $desc";
        like $readme_content, $regex, $message;
    }
}

done_testing();
