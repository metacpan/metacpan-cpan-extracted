

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'HTML::Tested',
    VERSION_FROM => 'lib/HTML/Tested.pm', # finds \$VERSION
    AUTHOR       => 'Boris Sukholitko (boriss@gmail.com)',
    ABSTRACT     => 'This module allows creation of different HTML widgets with the built-in means of testing them',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Class::Data::Inheritable' => '',
		     'Class::Accessor' => '',
		     'HTML::Entities' => '',
		     'Class::Singleton' => '',
		     'Crypt::CBC' => '2.22',
		     'Crypt::Blowfish' => '',
		     'Digest::CRC' => '',
		     'File::Slurp' => '',
		     'DateTime' => '',
		     'DateTime::Format::Strptime' => '',
		     'Data::Dumper' => '',
		     'Template' => '',
		     'Math::Combinatorics' => ''
		     , 'Text::Diff' => ''
                    },
);
