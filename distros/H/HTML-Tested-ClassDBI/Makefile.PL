

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'HTML::Tested::ClassDBI',
    VERSION_FROM => 'lib/HTML/Tested/ClassDBI.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'Enhances HTML::Tested to work with Class::DBI classes',
    PREREQ_PM    => {
                     'Test::TempDatabase' => '0.13',
		     'Class::DBI::Pg::More' => '0.04',
		     'HTML::Tested' => '0.41', 'File::MMagic' => ''
                    },
);
