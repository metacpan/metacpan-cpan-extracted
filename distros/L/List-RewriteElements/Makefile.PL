use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'List::RewriteElements',
    AUTHOR          => 'James E Keenan (jkeenan@pobox.com)',
    VERSION_FROM    => 'lib/List/RewriteElements.pm',
    ABSTRACT_FROM   => 'lib/List/RewriteElements.pm',
    PREREQ_PM       => {
                     'Carp'             => 0,
                     'Cwd'              => 0,
                     'File::Basename'   => 0,
                     'File::Copy'       => 0,
                     'File::Spec'       => 0,
                     'File::Temp'       => 0,
                     'Test::Simple'     => 0.44,
                     'Tie::File'        => 0,
                    },
    ($mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'Test::Simple' => 0.44,
                    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/List-RewriteElements/',
            repository => {
                url => 'https://github.com/jkeenan/List-RewriteElements.git',
                web => 'https://github.com/jkeenan/List-RewriteElements',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/jkeenan/List-RewriteElements/issues',
            },
        },
    })),
);
