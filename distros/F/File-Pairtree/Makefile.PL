use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    EXE_FILES           => [ 'pt' ],
    NAME                => 'File::Pairtree',
    AUTHOR              => 'John A. Kunze <jak@ucop.edu>',
    VERSION_FROM        => 'VERSION',
    ABSTRACT            => 'pt command and routines to manage pairtrees',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'BSD')
      : ()),
    PM			=> {
	'lib/File/Pairtree.pm'	=> 'blib/lib/File/Pairtree.pm'
    },
    PL_FILES            => {},
# xxx do we really need Carp?
    PREREQ_PM         => {
	'Carp'		=> '0',
	'Pod::Usage'	=> '0',
	'Getopt::Long'	=> '0',
	'File::Glob'	=> '0',
	'File::Find'	=> '0',
	'File::Path'	=> '0',
	'File::OM'	=> '0.21',
	'File::Value'	=> '1.01',
	'File::Namaste'	=> '1.01',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Value-*' },
);
