use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> "Digest::BLAKE3",
    VERSION_FROM	=> "lib/Digest/BLAKE3.pm",
    ABSTRACT_FROM	=> "lib/Digest/BLAKE3.pm",
    AUTHOR		=> 'Bo Lindbergh <blgl@stacken.kth.se>',
    LICENSE		=> "perl_5",
    PREREQ_PM		=> {
	parent		=> 0,
	Digest::base	=> 0,
    },
    LIBS		=> "-lblake3",
);

