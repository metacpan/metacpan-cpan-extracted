use ExtUtils::MakeMaker;
require 5.006;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'ExtUtils::ModuleMaker',
    VERSION_FROM => 'lib/ExtUtils/ModuleMaker.pm',
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Better than h2xs for creating modules',
    EXE_FILES    => [ 'scripts/modulemaker' ],
    PREREQ_PM    => {
        Getopt::Std     => 0, # in the Perl core
        File::Basename  => 0, # in the Perl core
        File::Path      => 0, # in the Perl core
        ($^O =~ /Win32/ ? (Win32 => 0) : ()),
        File::Save::Home => 0.03,
    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'IO::Capture' => 0,
                     'Test::More' => 0.44,
                    },
    LICENSE      => "perl",
    test        => { TESTS => join q{ }, map {glob} qw( t/*.t t/*/*.t ) },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/ExtUtils-ModuleMaker/',
            repository => {
                url => 'https://github.com/jkeenan/extutils-modulemaker.git',
                web => 'https://github.com/jkeenan/extutils-modulemaker',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=ExtUtils-ModuleMaker',
            },
        },
    })),
);

