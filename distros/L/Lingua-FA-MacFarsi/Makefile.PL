use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::FA::MacFarsi',
    'VERSION_FROM'	=> 'MacFarsi.pm',
    'ABSTRACT_FROM'	=> 'MacFarsi.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmacfa.h tomacfa.h' },
    'PREREQ_PM'	  	=> {
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

