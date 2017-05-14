use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'HTML::FormatNroff',	
	DISTNAME => 'FormatNroff',	
	VERSION => '0.11',
	dist => { COMPRESS => "gzip", SUFFIX=>"gz" },
);
