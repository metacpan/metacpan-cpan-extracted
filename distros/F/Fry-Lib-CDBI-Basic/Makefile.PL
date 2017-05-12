use ExtUtils::MakeMaker;
WriteMakefile(NAME=>'Fry::Lib::CDBI::Basic',
	VERSION_FROM=>'lib/Fry/Lib/CDBI/Basic.pm',
	PREREQ_PM=>{Fry::Shell=>'0.15' }
);
