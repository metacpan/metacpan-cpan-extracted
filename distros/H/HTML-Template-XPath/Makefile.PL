use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::Template::XPath',
    'VERSION_FROM' => 'lib/HTML/Template/XPath.pm', # finds $VERSION
    'PREREQ_PM'	=> {XML::LibXML => 1.31,
			HTML::Template => 1.8,
			IO::File => 0},
);
