use ExtUtils::MakeMaker;

require 5.006001;

do "mkheader" or die $@ || "mkheader: $!";

WriteMakefile(
    'NAME'		=> 'Lingua::KO::MacKorean',
    'VERSION_FROM'	=> 'MacKorean.pm',
    'ABSTRACT_FROM'	=> 'MacKorean.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> { FILES=> 'fmmacko.h tomacko.h' },
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);

