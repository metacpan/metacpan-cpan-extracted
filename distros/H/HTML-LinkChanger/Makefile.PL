use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'	=> 'HTML::LinkChanger',
	'VERSION_FROM' => 'lib/HTML/LinkChanger.pm', # finds $VERSION
	'PREREQ_PM' => {
			'HTML::Parser' => 3,
			'HTML::Tagset' => 3,
			'URI' => 1
		}
);
