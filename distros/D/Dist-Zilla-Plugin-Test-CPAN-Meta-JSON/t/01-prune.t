use strict;
use warnings;
use Test::More 0.88 tests => 2;
use autodie;
use Test::DZil;
use Moose::Autobox;

subtest 'No META.json' => sub {
    plan tests => 1;
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'Test::CPAN::Meta::JSON',)
                ),
            },
        },
    );

    $tzil->build;

    my $has_metajson_test = grep(
        $_->name eq 'xt/release/meta-json.t',
        $tzil->files->flatten
    );
    ok(!$has_metajson_test, 'meta-json.t was pruned out');
};

subtest 'META.json' => sub {
    plan tests => 2;
    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZT' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    ('GatherDir', 'MetaJSON', 'Test::CPAN::Meta::JSON',)
                ),
            },
        },
    );

    $tzil->build;

    my $has_metajson_test = grep(
        $_->name eq 'xt/release/meta-json.t',
        $tzil->files->flatten
    );
    ok($has_metajson_test, 'meta-json.t exists');

    my $meta_test = $tzil->slurp_file('build/xt/release/meta-json.t');
    like($meta_test, qr{\Qmeta_json_ok();\E}, 'We have a meta-json test');
};

END { # Remove (empty) dir created by building the dists
    eval 'use File::Path 2.08';
    File::Path::remove_tree('tmp') unless $@;
}
