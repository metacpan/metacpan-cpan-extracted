use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'Git::Reduce::Tests',
    VERSION_FROM => 'lib/Git/Reduce/Tests.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Create a branch with fewer test files for faster development',
    MIN_PERL_VERSION => '5.006',
    EXE_FILES    => [ 'scripts/reduce-tests' ],
    PREREQ_PM    => {
                     'Carp' => 0,
                     'Cwd' => 0,
                     'Data::Dumper' => 0,
                     'File::Find' => 0,
                     'Getopt::Long' => 0,
                     'Git::Wrapper' => 0.034,
                    },
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) => {
                     'Test::Simple' => 0.44,
                    },
    LICENSE      => "perl",
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/Git-Reduce-Tests/',
            repository => {
                url => 'https://github.com/jkeenan/git-reduce-tests.git',
                web => 'https://github.com/jkeenan/git-reduce-tests',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Git-Reduce-Tests',
            },
        },
    })),
);
