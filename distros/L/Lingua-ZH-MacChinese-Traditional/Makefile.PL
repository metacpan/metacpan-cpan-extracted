use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::ZH::MacChinese::Traditional',
    'VERSION_FROM'	=> 'Traditional.pm',
    'ABSTRACT_FROM'	=> 'Traditional.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmaccnt.h tomaccnt.h' },
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

