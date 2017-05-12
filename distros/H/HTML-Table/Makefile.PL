use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::Table',
    'ABSTRACT_FROM' => 'lib/HTML/Table.pm',
    'VERSION_FROM' => 'lib/HTML/Table.pm', # finds $VERSION
    'LICENSE' => 'perl',
    'AUTHOR' => 'Anthony Peacock <a.peacock@chime.ucl.ac.uk',
);
