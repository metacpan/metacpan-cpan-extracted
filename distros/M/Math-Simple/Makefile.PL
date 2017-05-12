

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Math::Simple',
    VERSION_FROM => 'lib/Math/Simple.pm', # finds \$VERSION
    AUTHOR       => 'Linda Walsh (LAWALSH@cpan.org)',
    ABSTRACT     => 'very basic, commonly used Math funcs',
    BUILD_REQUIRES=> { 'ExtUtils::MakeMaker' => '6.82', },
		LICENSE				=> 'perl',
		PERM_DIR			=> '0755',
		PERM_RW				=> '0664',
		PERM_RWX			=> '0775',
    PREREQ_PM    => {'Xporter'	=>	'0.0.11',
                    },
		TEST_REQUIRES=> { },
		dist				=> { TAR=> 'ptar' , TARFLAGS=> "-cvf" },
		test				=> { TESTS => '' }
);
