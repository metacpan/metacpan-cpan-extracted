use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'IO::Capture::Extended',
    VERSION_FROM    => 'lib/IO/Capture/Extended.pm',
    ABSTRACT_FROM   => 'lib/IO/Capture/Extended.pm',
    AUTHOR          => 'James E Keenan (jkeenan@cpan.org)',
    PREREQ_PM    => {
                     'IO::Capture'  => 0.05,
                    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'Test::Simple' => 0.44,
                    },
    LICENSE      => "perl",
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/IO-Capture-Extended/',
            repository => {
                url => 'https://github.com/jkeenan/io-capture-extended.git',
                web => 'https://github.com/jkeenan/io-capture-extended',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Capture-Extended',
            },
        },
    })),
);
