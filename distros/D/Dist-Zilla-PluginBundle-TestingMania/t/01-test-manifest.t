use strict;
use warnings;
use Test::More 0.88 tests => 5;
use autodie;
use Test::DZil;
use Moose::Autobox;
use Path::Tiny;

subtest 'default' => sub {
    plan tests => 2;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT-Sample' },
        { add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'MetaYAML',
                    'MetaJSON',
                    '@TestingMania'
                ),
                'source/lib/DZT/Sample.pm' => '',
            }
        },
    );
    $tzil->build;

    my @tests = map $_->name =~ m{^t/} ? $_->name : (), $tzil->files->flatten;
    is_filelist(\@tests, [qw(t/00-compile.t)], 'tests are all there')
        or diag explain { have => \@tests, want => [qw(t/00-compile.t)] };

    my @xtests = map $_->name =~ m{^xt/} ? path($_->name)->basename : (), $tzil->files->flatten;
    my @want = qw(
        critic.t            eol.t               kwalitee.t          unused-vars.t
        minimum-version.t   dist-manifest.t     portability.t       pod-coverage.t
        test-version.t      cpan-changes.t      synopsis.t          no-tabs.t
        pod-linkcheck.t     pod-syntax.t        distmeta.t          meta-json.t
        mojibake.t
    );
    is_filelist(\@xtests, \@want, 'xtests are all there')
        or diag explain { have => \@xtests, want => \@want };
};

subtest 'enable' => sub {
    plan skip_all => 'all tests are on by default now';#tests => 1;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        { add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'MetaYAML',
                    'MetaJSON',
                    ['@TestingMania' => {enable => 'ConsistentVersionTest'} ],
                ),
                'source/lib/DZT/Sample.pm' => '',
            }
        }
    );
    $tzil->build;

    my $has_consistentversiontest = grep path($_->name)->basename eq 'consistent-version.t', $tzil->files->flatten;
    ok $has_consistentversiontest, 'ConsistentVersionTest added itself';
    diag explain map { $_->name } $tzil->files->flatten;
};

subtest 'disable' => sub {
    plan tests => 2;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        { add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'MetaYAML',
                    'MetaJSON',
                    ['@TestingMania' => { disable => [qw(Test::EOL Test::NoTabs)] } ],
                ),
                'source/lib/DZT/Sample.pm' => '',
            }
        }
    );
    $tzil->build;

    my @files = map { path($_->name)->basename } $tzil->files->flatten;
    my $has_eoltest = grep { $_ eq 'eol.t' } @files;
    ok !$has_eoltest, 'EOLTests was disabled';

    my $has_notabstest = grep { $_ eq 'no-tabs.t' } @files;
    ok !$has_notabstest, 'Test::NoTabs was disabled';
};

subtest 'back-compat' => sub {
    plan tests => 1;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        { add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'MetaYAML',
                    'MetaJSON',
                    ['@TestingMania' => { disable => [qw(NoTabsTests)] } ],
                ),
                'source/lib/DZT/Sample.pm' => '',
            }
        }
    );
    $tzil->build;

    my @files = map { path($_->name)->basename } $tzil->files->flatten;
    my $has_notabstest = grep { $_ eq 'no-tabs.t' } @files;
    ok !$has_notabstest, 'Test::NoTabs was disabled by using the back-compat name (NoTabsTests)';
};

subtest 'nonexistent test' => sub {
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'MetaYAML', 'MetaJSON', ['@TestingMania' => { disable => 'Nonexistent', enable => 'Test::EOL' }])
                ),
                'source/lib/DZT/Sample.pm' => '',
            },
        },
    );
    $tzil->build;

    my @tests = map $_->name =~ m{^x?t/} ? path($_->name)->basename : (), $tzil->files->flatten;
    my $has_eoltest = grep { $_ eq 'eol.t' } @tests;
    ok $has_eoltest, 'EOLTests enbled';

    is_filelist \@tests, [qw(
        00-compile.t        critic.t            eol.t               test-version.t
        pod-coverage.t      synopsis.t          dist-manifest.t     meta-json.t
        cpan-changes.t      distmeta.t          unused-vars.t       kwalitee.t
        no-tabs.t           minimum-version.t   portability.t       pod-linkcheck.t
        pod-syntax.t        mojibake.t
    )];
};
