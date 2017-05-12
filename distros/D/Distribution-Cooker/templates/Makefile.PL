use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => '[% module %]',
	'ABSTRACT'     => '[% description %]',
	'VERSION_FROM' => 'lib/[% module_path %]',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0',
		},

	clean  => { FILES    => q|[% module_dist %]-*| },
	);
