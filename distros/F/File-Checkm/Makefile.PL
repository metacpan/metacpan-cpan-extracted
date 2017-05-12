use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    EXE_FILES           => [ 'checkm' ],
    NAME                => 'File::Checkm',
    AUTHOR              => 'John A. Kunze <jak@ucop.edu>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT            => 'checkm (command) and routines to manage manifests',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'      => 'BSD')
      : ()),
    PM			=> {
	'lib/File/Checkm.pm'	=> 'blib/lib/File/Checkm.pm'
    },
    PL_FILES            => {},
    PREREQ_PM         => {
	'Carp'		=> '0',
	'Pod::Usage'	=> '0',
	'Getopt::Long'	=> '0',
	'File::Find'	=> '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Value-*' },
);
