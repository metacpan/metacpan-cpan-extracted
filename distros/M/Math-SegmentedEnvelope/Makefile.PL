use strict;
use warnings;
use ExtUtils::MakeMaker;

# dlopen is in libc on *BSD/macOS, needs -ldl on Linux
my $dl_lib = '';
if ($^O !~ /^(?:openbsd|freebsd|netbsd|darwin|dragonfly)$/) {
    $dl_lib = '-ldl';
}

WriteMakefile(
    NAME             => 'Math::SegmentedEnvelope',
    VERSION_FROM     => 'lib/Math/SegmentedEnvelope.pm',
    ABSTRACT_FROM    => 'lib/Math/SegmentedEnvelope.pm',
    AUTHOR           => 'Yegor Korablev <egor@cpan.org>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    PREREQ_PM        => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    XS               => { 'SegmentedEnvelope.xs' => 'SegmentedEnvelope.c' },
    OBJECT           => 'SegmentedEnvelope$(OBJ_EXT) tinyexpr$(OBJ_EXT) morpher_jit$(OBJ_EXT)',
    LIBS             => ["-lm $dl_lib"],
    DEFINE           => '',
    INC              => '-I.',
    clean            => { FILES => 'Math-SegmentedEnvelope-* SegmentedEnvelope.c' },
    META_MERGE       => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/Math-SegmentedEnvelope.git',
                web  => 'https://github.com/vividsnow/Math-SegmentedEnvelope',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/Math-SegmentedEnvelope/issues',
            },
        },
        no_index => {
            directory => [ 'bench', 'eg', 'examples', 't' ],
            file      => [ 'bench/PurePerl.pm' ],
        },
        provides => {
            'Math::SegmentedEnvelope' => {
                file    => 'lib/Math/SegmentedEnvelope.pm',
                version => '0.03',
            },
            'Math::SegmentedEnvelope::Static' => {
                file    => 'lib/Math/SegmentedEnvelope.pm',
                version => '0.03',
            },
        },
    },
);
