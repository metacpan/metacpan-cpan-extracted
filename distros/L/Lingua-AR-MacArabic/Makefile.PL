use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::AR::MacArabic',
    'VERSION_FROM'	=> 'MacArabic.pm',
    'ABSTRACT_FROM'	=> 'MacArabic.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmacar.h tomacar.h' },
    'PREREQ_PM'	  	=> {
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

