use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT =>'Convert between Traditional and Simplified Chinese characters',
    AUTHOR	=> 'David Chan (david@sheetmusic.org.uk)',
    NAME	=> 'Lingua::ZH::HanConvert',
    VERSION_FROM => 'HanConvert.pm',
    EXE_FILES	=> ['trad2simp', 'simp2trad'],	# standalone perl scripts
);
