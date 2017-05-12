use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    EXE_FILES		=> [ 'nam' ],
    NAME                => 'File::Namaste',
    AUTHOR              => 'John A. Kunze <jak@ucop.edu>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT            => 'nam command and routines to manage NAMe-AS-TExt tags',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PM			=> {
	'lib/File/Namaste.pm'	=> 'blib/lib/File/Namaste.pm',
    },
    PL_FILES            => {},
    PREREQ_PM => {
	'Getopt::Long'	=> 0,
	'Pod::Usage'	=> 0,
	'File::Spec'	=> 0,
	'File::OM'	=> 0.20,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Namaste-*' },
);

