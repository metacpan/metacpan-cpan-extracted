use ExtUtils::MakeMaker;
require 5.008;

my $mm_ver = ExtUtils::MakeMaker->VERSION;

WriteMakefile(
    NAME         => 'File::Copy::Recursive::Reduced',
    VERSION_FROM => 'lib/File/Copy/Recursive/Reduced.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Recursive copying of files and directories within Perl 5 toolchain',
    MIN_PERL_VERSION => '5.8.0',
    # Modules needed to compile, build or actually run this distribution:
    PREREQ_PM    => {
                        'File::Copy'    => 0,
                        'File::Find'    => 0,
                        'File::Path'    => 0,
                        'File::Spec'    => 0,
                    },
    # Modern EU::MM enables us to identify modules required only for the test
    # suite.
    ( $mm_ver < 6.63_03 ? 'BUILD_REQUIRES' : 'TEST_REQUIRES' ) =>  {
                        'Test::Simple'  => 0.44,
                        'Capture::Tiny' => 0,
                        'File::Path'    => 0,
                        'File::Spec'    => 0,
                        'File::Temp'    => 0,
                        'Path::Tiny'    => 0,
                    },
    # Modern EU::MM enables 'make dist' to write good META.json (and META.yml)
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            homepage => 'http://thenceforward.net/perl/modules/File-Copy-Recursive-Reduced/',
            repository => {
                url => 'https://github.com/jkeenan/file-copy-recursive-reduced.git',
                web => 'https://github.com/jkeenan/file-copy-recursive-reduced',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=File-Copy-Recursive-Reduced',
            },
        },
    })),
    ($mm_ver < 6.31 ? () : (LICENSE => 'perl_5')),
);


__END__

        File::Copy      => 0,
        File::Spec      => 0,
        Test::Deep      => 0,
        Test::File      => 0,
        File::Temp      => 0,
        Test::Warn      => 0,
        File::Glob      => 0,
        Test::Exception => 0,
        Cwd             => 0,
        File::Spec      => 0,
        Path::Tiny      => 0,
