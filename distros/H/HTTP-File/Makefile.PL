use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'VERSION_FROM' => 'File.pm', # finds $VERSION
    'NAME'	=> 'HTTP::File',
	      'PREREQ_PM' => { 'HTTP::Headers::UserAgent', '1.00' }
);
