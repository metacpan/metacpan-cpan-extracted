use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'Devel::TraceVars',
	VERSION_FROM    => 'lib/Devel/TraceVars.pm',
	PREREQ_PM       => {
		'PadWalker'   => '0.10',
	},

	ABSTRACT_FROM  => 'lib/Devel/TraceVars.pm',
	AUTHOR         => 'Emmanuel Rodriguez <potyl@cpan.org>',
	
#	(MM->can('signature_target') ? (SIGN => 1) : ()),
);
