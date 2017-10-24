#!perl

use 5.006;
use strict;
use warnings;

use CPAN::Meta::YAML;
use Test::DZil;
use Test::Fatal;
use Test::MockModule;
use Test::More;
use Path::Tiny;

use lib 't/lib';
use Local::HTTP::Tiny::Mock;

# DZ5/DZ6 use the lib from DZ4/lib
use lib 'corpus/dist/DZ4/lib/';

use Dist::Zilla::Plugin::AutoPrereqs::Perl::Critic;
use Perl::Critic;

my $http_tiny = Test::MockModule->new('HTTP::Tiny');
$http_tiny->mock( 'get', Local::HTTP::Tiny::Mock::get_200() );

{
    note('download the package informarion and create a cache file');

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ4' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',
                        {
                            critic_config => 'perl_critic_config.txt',
                        },
                    ],
                ),
            },
        },
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $root_dir        = path( $tzil->root );
    my $cache_file_name = '.perlcritic_package.yml';
    my $cache_file      = $root_dir->child($cache_file_name);

    ok( -f $cache_file, "The cache file '$cache_file_name' was created" );

    my $yaml = CPAN::Meta::YAML->read_string( $cache_file->slurp() );

    # HTTP::Tiny is mocked, we therefore know that we've "downloaded" 1.130
    is( ${$yaml}[0]->{version}, '1.130', '... with the correct version' );
}

{
    note('download the package informarion and create a cache file');

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ5' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',
                        {
                            critic_config => 'perl_critic_config.txt',
                        },
                    ],
                ),
            },
        },
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $root_dir        = path( $tzil->root );
    my $cache_file_name = '.perlcritic_package.yml';
    my $cache_file      = $root_dir->child($cache_file_name);

    ok( -f $cache_file, "The cache file '$cache_file_name' exists" );

    my $yaml = CPAN::Meta::YAML->read_string( $cache_file->slurp() );

    # HTTP::Tiny is mocked, we therefore know that we've "downloaded" 1.130
    is( ${$yaml}[0]->{version}, '1.130', '... with an updated, correct version' );
}

{
    note('download the package informarion and create a cache file');

    my $tzil = Builder->from_config(
        { dist_root => 'corpus/dist/DZ6' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    [
                        'AutoPrereqs::Perl::Critic',
                        {
                            critic_config => 'perl_critic_config.txt',
                        },
                    ],
                ),
            },
        },
    );

    is( exception { $tzil->build; }, undef, 'Built dist successfully' );

    my $root_dir        = path( $tzil->root );
    my $cache_file_name = '.perlcritic_package.yml';
    my $cache_file      = $root_dir->child($cache_file_name);

    ok( -f $cache_file, "The cache file '$cache_file_name' exists" );

    my $yaml = CPAN::Meta::YAML->read_string( $cache_file->slurp() );

    # HTTP::Tiny is mocked, we therefore know that we've "downloaded" 1.130
    is( ${$yaml}[0]->{version}, '99999999', '... with the correct version (not updated)' );
}

done_testing();

# vim: ts=4 sts=4 sw=4 et: syntax=perl
