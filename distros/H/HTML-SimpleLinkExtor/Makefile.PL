use ExtUtils::MakeMaker 6.64;

require 5.008;

eval "use Test::Manifest 1.21";   
   
WriteMakefile(
	'NAME'         => 'HTML::SimpleLinkExtor',
	'ABSTRACT'     => 'Extract links from HTML',
	'VERSION_FROM' => 'lib/HTML/SimpleLinkExtor.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker' => '6.64',
		},

	'TEST_REQUIRES' => {
		'Test::More'      => '0.96',  # for subtest, done_testing
		'Test::Output'    => '0',
		},

	'PREREQ_PM'     => { 
		'HTML::LinkExtor' => '1.28',
		'LWP::UserAgent'  => '0',
		'URI'             => '1.09',
		'URI::file'       => '0',
		},

	'EXE_FILES'    => [ 'scripts/linktractor' ],

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git@github.com:briandfoy/html-simplelinkextor.git',
				web  => 'https://github.com/briandfoy/html-simplelinkextor',
				},
			},
		},

	clean  => { FILES    => q|HTML-SimpleLinkExtor-*| },
	);
