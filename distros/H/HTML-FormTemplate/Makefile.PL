use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME	=> 'HTML::FormTemplate',
	VERSION_FROM => 'lib/HTML/FormTemplate.pm', # finds $VERSION
	PREREQ_PM => {
		'Class::ParamParser' => 1.041,
		'HTML::EasyTags' => 1.071,
		'Data::MultiValuedHash' => 1.081,
		'CGI::MultiValuedHash' => 1.09,
	},
);
