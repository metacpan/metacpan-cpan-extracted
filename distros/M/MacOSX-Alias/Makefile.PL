# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.008;

die "OS unsupported! This is a Mac OS X module!\n" unless $^O eq 'darwin';

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'MacOSX::Alias',
	'ABSTRACT'     => 'Read or create aliases on Mac OS X',
	'VERSION_FROM' => 'lib/Alias.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More'     => '0',
		'MacPerl'        => '0',
		'Mac::Errors'    => '0',
		'Mac::Files'     => '0',
		'Mac::Resources' => '0',		
		},

	'PM'           => {
		'lib/Alias.pm'         => '$(INST_LIBDIR)/Alias.pm',
		},

	'MAN3PODS'     => {
		'lib/Alias.pm' => '$(INST_MAN3DIR)/MacOSX::Alias.3',
		},

	clean  => { FILES    => q|MacOSX-Alias-*| },

	);
