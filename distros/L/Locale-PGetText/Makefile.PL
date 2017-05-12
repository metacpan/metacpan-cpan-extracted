use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => "Locale::PGetText",
    VERSION_FROM => 'PGetText.pm', 
    EXE_FILES => [ 'MsgFormat','XText' ],
    dist => {
	COMPRESS => 'gzip',	
    }

);

