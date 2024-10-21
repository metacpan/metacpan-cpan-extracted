use strict;
use warnings;
use autodie;
use Test::More 0.94;# tests => 2;
use Test::DZil;

my $rc_content = do { local $/; <DATA>};
my $test_name = 'xt/author/critic.t';

subtest 'default' => sub {
    plan tests => 3;

    my $critic_config = 'perlcritic.rc';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::Perl::Critic')
                ),
                "source/$critic_config" => $rc_content,
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{$critic_config}, 'Right config file used');
};

subtest '.perlcriticrc' => sub {
    plan tests => 3;

    my $critic_config = '.perlcriticrc';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::Perl::Critic' => { critic_config => $critic_config}])
                ),
                "source/$critic_config" => $rc_content,
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{$critic_config}, 'Right config file used')
};

subtest 'empty' => sub {
    plan tests => 3;

    my $critic_config = 'perlcritic.rc';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::Perl::Critic', { critic_config => '' }])
                ),
                "source/$critic_config" => $rc_content,
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{$critic_config}, 'Right config file used')
};

subtest 'undef' => sub {
    plan tests => 3;

    my $critic_config = 'perlcritic.rc';
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::Perl::Critic', { critic_config => undef }])
                ),
                "source/$critic_config" => $rc_content,
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{$critic_config}, 'Right config file used')
};

subtest 'files' => sub {
    plan tests => 3;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::Perl::Critic', { files => 'lib/My/Module.pm' }])
                ),
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{all_critic_ok\(\@\{\[\s*"lib/My/Module\.pm"},
      'Includes file');
};

subtest 'finder' => sub {
    plan tests => 4;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', ['Test::Perl::Critic', { finder => ':InstallModules' }])
                ),
                'source/lib/My/Module.pm' => "package My::Module; 1;",
                'source/inc/My/Include.pm' => "package My::Include; 1;",
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr{all_critic_ok\(\@\{\[\s*"lib/My/Module\.pm"},
      'Includes installed modules');
    unlike($critic_test, qr{inc/My/Include\.pm}, "Doesn't include inc modules");
};

done_testing;

END { # Remove (empty) dir created by building the dists
    require File::Path;
    File::Path::rmtree('tmp');
}

__DATA__
severity = 3
