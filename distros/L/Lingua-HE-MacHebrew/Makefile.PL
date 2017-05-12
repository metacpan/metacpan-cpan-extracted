use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::HE::MacHebrew',
    'VERSION_FROM'	=> 'MacHebrew.pm',
    'ABSTRACT_FROM'	=> 'MacHebrew.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmache.h tomache.h' },
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

