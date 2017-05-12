use strict;
use warnings;
use Test::More 0.94 tests => 2;
use Test::CPAN::Changes;
use autodie;
use Test::DZil;

my $changes = do { local $/; <DATA>};

subtest 'Changes' => sub {
    plan tests => 2;

    my $changelog = 'Changes';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::CPAN::Changes')
                ),
                "source/$changelog" => $changes,
            },
        },
    );

    $tzil->build;

    my $has_changelog = grep(
        $_->name eq $changelog,
        @{ $tzil->files }
    );
    ok($has_changelog, 'changelog exists')
        or diag explain @{ $tzil->files };

    my $changes_test = $tzil->slurp_file('build/xt/release/cpan-changes.t');
    like($changes_test, qr{\Qchanges_file_ok('Changes');\E}, 'We have a cpan-changes test');
};

subtest 'CHANGES' => sub {
    plan tests => 2;

    my $changelog = 'CHANGES';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::CPAN::Changes' => {changelog => $changelog} ])
                ),
                "source/$changelog" => $changes,
            },
        },
    );

    $tzil->build;

    my $has_changelog = grep(
        $_->name eq $changelog,
        @{ $tzil->files }
    );
    ok($has_changelog, 'changelog exists')
        or diag explain @{ $tzil->files };

    my $changes_test = $tzil->slurp_file('build/xt/release/cpan-changes.t');
    like($changes_test, qr{\Qchanges_file_ok('$changelog');\E}, 'We have a cpan-changes test');
};

END { # Remove (empty) dir created by building the dists
    require File::Path;
    File::Path::rmtree('tmp');
}

__DATA__
Revision history for perl module Foo::Bar

    0.02 2009-07-17

     - Added more foo() tests

    0.01 2009-07-16

     - Initial release
