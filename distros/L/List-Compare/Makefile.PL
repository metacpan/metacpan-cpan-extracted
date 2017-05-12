use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME            => 'List::Compare',
    AUTHOR          => 'James E Keenan (jkeenan@cpan.org)',
    VERSION_FROM    => 'lib/List/Compare.pm',
    ABSTRACT_FROM   => 'lib/List/Compare.pm',
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'IO::CaptureOutput' => 0,
                     'Test::Simple' => 0.10,
                    },
    LICENSE      => "perl",
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/List-Compare/',
            repository => {
                url => 'https://github.com/jkeenan/list-compare.git',
                web => 'https://github.com/jkeenan/list-compare',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=List-Compare',
            },
        },
    })),
);
