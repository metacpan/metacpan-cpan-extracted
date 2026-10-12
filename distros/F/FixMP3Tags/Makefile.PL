use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'FixMP3Tags',
    VERSION_FROM  => 'lib/FixMP3Tags.pm',
    AUTHOR        => 'vr-ski 166657596+vr-ski@users.noreply.github.com',
    ABSTRACT      => 'Fix MP3 tags from directory structure',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM     => {
        'MP3::Tag'      => '1.16',
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.22',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.90',
    },
    EXE_FILES     => ['bin/fix-mp3-tags'],
    test          => { TESTS => 't/*.t' },
    LICENSE       => 'freebsd',
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vr-ski/fix-mp3-tags.git',
                web  => 'https://github.com/vr-ski/fix-mp3-tags',
            },
            bugtracker => {
                web => 'https://github.com/vr-ski/fix-mp3-tags/issues',
            },
        },
    },
);
