use ExtUtils::MakeMaker 6.46;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Distribution::Cooker',
	'ABSTRACT'     => 'Create a module directory from your own templates',
	'VERSION_FROM' => 'lib/Distribution/Cooker.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'       => '0.94',
		'Config::IniFiles' => '0',
		'Template'         => '0',
		},

	'EXE_FILES' => [ 'script/dist_cooker' ],
		
	'DIR' => [], # do not look in templates for Makefile.PL

	clean  => { FILES    => q|Distribution-Cooker-*| },

	META_MERGE => {
		resources => {
			Repository => 'http://github.com/briandfoy/distribution-cooker/'
			}
		},

	);
