#
## Copyright (C) Carlos Celso.
## All rights reserved.
#
	use 5.006001;
	use ExtUtils::MakeMaker;

	our $VERSION = "2023.111.1";

	my %makefile_param =
	(
		NAME => 'Math::Notation::PostfixInfix',
		VERSION_FROM => 'lib/Math/Notation/PostfixInfix.pm',
		ABSTRACT_FROM => 'lib/Math/Notation/PostfixInfix.pod',
		AUTHOR => 'Carlos Celso <CCELSO@cpan.org>',
		LICENSE => 'GPL_3',
		META_MERGE =>
		{
			'meta-spec' => { version => 2 },
			resources =>
			{
				license => 'http://www.gnu.org/licenses/gpl-3.0.html',
				bugtracker => { web => 'https://sourceforge.net/p/csi-math-notation-postfixinfix/tickets/' },
				repository =>
				{
					type => 'git',
					url => 'https://sourceforge.net/projects/csi-math-notation-postfixinfix/files',
					web => 'https://sourceforge.net/projects/csi-math-notation-postfixinfix/',
				},
			},
		},
		CONFIGURE_REQUIRES =>
		{
			'ExtUtils::MakeMaker' => 0,
		},
		BUILD_REQUIRES => {},
		PREREQ_PM => {},
		TEST_REQUIRES =>
		{
			'Test::More' => 0,
		},
		dist => { COMPRESS => "gzip -9", SUFFIX => "gz" },
	);
	#
	## test makemaker version and supported options
	#
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.63_03); } )
	{
		$makefile_param{PREREQ_PM} = 
		{
			%{ delete $makefile_param{TEST_REQUIRES} },
			%{ delete $makefile_param{BUILD_REQUIRES} },
		};
	}
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } )
	{
		delete $makefile_param{CONFIGURE_REQUIRES};
	}
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.48) } )
	{
		delete $makefile_param{MIN_PERL_VERSION};
	}
	#
	## write my makefile
	#
	WriteMakefile(%makefile_param);

##ENDED
