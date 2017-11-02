use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'File::Save::Home',
    VERSION_FROM => 'lib/File/Save/Home.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Place file safely under user home directory',
    LICENSE      => "perl",
    PREREQ_PM    => {
                     'Carp'         => 0,
                     'File::Find'   => 0,
                     'File::Path'   => 0,
                     'File::Spec'   => 0,
                     'File::Temp'   => 0,
                     'Test::Simple' => 0.44,
                    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'String::Random' => 0,
                    },
    ( $mm_ver < 6.46    ? ()               : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/File-Save-Home/',
            repository => {
                url => 'https://github.com/jkeenan/file-save-home.git',
                web => 'https://github.com/jkeenan/file-save-home',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Save-Home',
            },
        },
    })),
);
