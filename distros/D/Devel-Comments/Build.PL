use 5.8.0;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name             => 'Devel::Comments',
    license                 => 'perl',
    dist_author             => 'Xiong Changnian <XIONG@cpan.org>',
    dist_version_from       => 'lib/Devel/Comments.pm',
    requires                => {
        'perl'                  => 5.008,
        'version'               => 0.77,
        'Text::Balanced'        => 2.0,
        'Data::Dumper'          => 0,
        'Filter::Simple'        => 0.80,
        'List::Util'            => 0,
    },
    build_requires          => {
        'Test::More'            => 0,
    },
    recommends              => {
        'perl'                  => 5.010_001,
        'Test::More'            => 0.94,
        'Test::Deep'            => 0,
        'Try::Tiny'             => 0,

        'IO::Capture::Stdout::Extended'     => 0,
        'IO::Capture::Stderr::Extended'     => 0,
        'IO::Capture::Sayfix'               => 0,
        'IO::Capture::Tellfix'              => 0,
    },
    add_to_cleanup          => [ 
        'Devel-Comments-*',
        'devel-comments-test.log',
    ],
    meta_merge              => {
        resources               => {
            repository              => 'http://github.com/Xiong/devel-comments',
        },
        keywords            => [
            'source filter', 
            'smart comments',
            'perl debugging',
            'development',
        ],
    },
);

$builder->create_build_script();

