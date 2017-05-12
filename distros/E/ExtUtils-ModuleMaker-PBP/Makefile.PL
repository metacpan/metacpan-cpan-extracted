

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'ExtUtils::ModuleMaker::PBP',
    VERSION_FROM => 'lib/ExtUtils/ModuleMaker/PBP.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'Create a Perl extension in the style of Damian Conway\'s Perl Best Practices',
    EXE_FILES    => [ 'scripts/mmkrpbp' ],
    PREREQ_PM    => {
        Test::More      => 0.44,
        Getopt::Std     => 0, # in the Perl core
        File::Basename  => 0, # in the Perl core
        File::Path      => 0, # in the Perl core
        ($^O =~ /Win32/ ? (Win32 => 0) : ()),
        ExtUtils::ModuleMaker    => 0.43_04,
    },
    test        => { TESTS => join q{ }, map {glob} qw( t/*.t t/*/*.t ) },
);
