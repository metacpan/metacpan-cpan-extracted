use strict;
use warnings;
use autodie;
use Test::More 0.94;# tests => 2;
use Test::DZil;

my $test_name = 'xt/author/critic-freenode.t';

subtest 'default' => sub {
    plan tests => 3;

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::Perl::Critic::Freenode')
                ),
            },
        },
    );

    $tzil->build;

    my $has_test = grep(
        $_->name eq $test_name,
        @{ $tzil->files }
    );
    ok($has_test, 'Perl::Critic::Freenode test exists')
        or diag explain @{ $tzil->files };

    my $critic_test = $tzil->slurp_file("build/$test_name");
    like($critic_test, qr{Test::Perl::Critic}, 'We have a Perl::Critic test');
    like($critic_test, qr/freenode/, 'We are using the freenode theme');
};

done_testing;

END { # Remove (empty) dir created by building the dists
    require File::Path;
    File::Path::rmtree('tmp');
}
