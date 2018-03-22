use strict;
use warnings;
use Test::More 0.96 tests => 3;
use Test::DZil;

subtest 'explicit version' => sub {
    plan tests => 2;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::MinimumVersion' => { max_target_perl => '5.10.1' }])
                ),
            },
        },
    );
    $tzil->build;

    my ($test) = map { $_->name eq 'xt/author/minimum-version.t' ? $_ : () } @{ $tzil->files };
    ok $test, 'minimum-version.t exists'
        or diag explain [ map { $_->name } @{ $tzil->files } ];

    like $test->content => qr{\Q5.10.1\E}, 'max_target_perl used in test';
};

subtest 'version from metayml' => sub {
    plan tests => 2;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::MinimumVersion')
                ),
            },
        },
    );
    $tzil->build;

    my ($test) = map { $_->name eq 'xt/author/minimum-version.t' ? $_ : () } @{ $tzil->files };
    ok $test, 'minimum-version.t exists'
        or diag explain [ map { $_->name } @{ $tzil->files } ];

    like $test->content => qr{metayml}, 'metayml used in test';
};

subtest 'develop prereq added' => sub {
    plan tests => 1;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/DZ1' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::MinimumVersion')
                ),
            },
        },
    );
    $tzil->build;

    my $prereqs = $tzil->prereqs->as_string_hash;
    ok exists $prereqs->{develop}->{requires}->{'Test::MinimumVersion'},
        'Test::MinimumVersion is a develop prereq',
        ;
};
