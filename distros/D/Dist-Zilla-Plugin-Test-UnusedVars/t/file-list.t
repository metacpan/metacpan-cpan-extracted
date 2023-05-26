use strict;
use warnings;
use Test::More 0.96 tests => 3;
use autodie;
use Test::DZil;
use List::Util qw( first );
use Path::Tiny;

subtest 'file list' => sub {
    my @files_to_test = qw(one two three);
    plan tests => scalar @files_to_test;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        { add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                ['Test::UnusedVars' => { files => \@files_to_test }],
            ),
        },
    });
    $tzil->build;

    my ($test) = first { $_->name eq 'xt/release/unused-vars.t' } @{ $tzil->files };
    like $test->content => qr{\Q$_} for @files_to_test;
};

subtest 'naughty filenames' => sub {
    my @files_to_test = qw(one' 'two);
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        { add_files => {
            'source/dist.ini' => simple_ini(
                'GatherDir',
                ['Test::UnusedVars' => { file => \@files_to_test }],
            ),
        },
    });
    $tzil->build;

    my ($test) = first { $_->name eq 'xt/release/unused-vars.t' } @{ $tzil->files };

    is(
      $test->content,
      <<'CONTENT',
use Test::More 0.96 tests => 1;
use Test::Vars;

subtest 'unused vars' => sub {
my @files = (
    '../one\'',
    '../\'two'
);
vars_ok($_) for @files;
};
CONTENT
      'filenames are rendered correctly',
    );
};

subtest 'all files' => sub {
    plan tests => 1;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        { add_files => {
            'source/dist.ini' => simple_ini('GatherDir', 'Test::UnusedVars'),
        },
    });
    $tzil->build;

    my ($test) = first { $_->name eq 'xt/release/unused-vars.t' } @{ $tzil->files };
    like $test->content => qr{\Qall_vars_ok};
};
