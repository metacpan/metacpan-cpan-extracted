use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    EXE_FILES		=> [ 'snag' ],
    NAME                => 'File::Value',
    AUTHOR              => 'John A. Kunze <jak@ucop.edu>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT            => 'snag command and routines supporting files as values',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PM			=> {
    	'lib/File/Value.pm'	=> 'blib/lib/File/Value.pm',
    },
    PL_FILES            => {},
    PREREQ_PM => {
        'Getopt::Long'	=> 0,
        'File::Copy'	=> 0,
        'File::Glob'	=> 0,
        'File::Spec'	=> 0,
        'Pod::Usage'	=> 0,
        'Fcntl'		=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Value-*' },
);
