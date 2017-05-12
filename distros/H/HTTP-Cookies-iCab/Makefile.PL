use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.14";
	
WriteMakefile
	(
	'NAME'           => 'HTTP::Cookies::iCab',
	'ABSTRACT'       => 'Cookie storage and management for iCab 3',
	'VERSION_FROM'   => 'lib/HTTP/Cookies/iCab.pm',
	'LICENSE'        => 'perl',
	'AUTHOR'         => 'brian d foy <bdfoy@cpan.org>',

	'PREREQ_PM'      => {
		'HTTP::Cookies'         => '1.25',
		'Text::Diff'            => '0',
		},
	
	clean => { FILES => 'HTTP-Cookies-iCab-*' },
	);

