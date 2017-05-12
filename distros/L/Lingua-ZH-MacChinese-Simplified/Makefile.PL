use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::ZH::MacChinese::Simplified',
    'VERSION_FROM'	=> 'Simplified.pm',
    'ABSTRACT_FROM'	=> 'Simplified.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmaccns.h tomaccns.h' },
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

