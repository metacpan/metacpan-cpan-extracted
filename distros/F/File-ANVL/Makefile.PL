use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    EXE_FILES		=> [ 'anvl', 'erc' ],
    NAME                => 'File::ANVL',
    AUTHOR              => 'John A. Kunze <jak@ucop.edu>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT            => 'commands and routines for ANVL, ERC, and OM',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PM			=> {
	'lib/File/ANVL.pm'	=> 'blib/lib/File/ANVL.pm',
	'lib/File/ERC.pm'	=> 'blib/lib/File/ERC.pm',
	'lib/File/OM.pm'	=> 'blib/lib/File/OM.pm',
    },
    PL_FILES            => {},
    PREREQ_PM => {
	'Text::Wrap'	=> 0,
	'File::Value'	=> '1.01',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-ANVL-*' },
);
