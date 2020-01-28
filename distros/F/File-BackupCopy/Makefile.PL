use strict;
use warnings;
use ExtUtils::MakeMaker;
use Module::Metadata;

my %makefile_args = (
    NAME              => 'File::BackupCopy',
    VERSION_FROM      => 'lib/File/BackupCopy.pm',
    ABSTRACT_FROM     => 'lib/File/BackupCopy.pm',
    LICENSE           => 'gpl_3',
    AUTHOR            => 'Sergey Poznyakoff <gray@gnu.org>',
    MIN_PERL_VERSION  => 5.014002,
    PREREQ_PM         => {
	'File::Temp'  => 0.23
    },
    TEST_REQUIRES     => {
	'File::Cmp' => 1.07
    },
    META_MERGE        => {
	'meta-spec' => { version => 2 },
        resources => {
	    repository => {
		type => 'git',
                url => 'git://git.gnu.org.ua/file-backup.git',
		web => 'http://git.gnu.org.ua/cgit/file-backup.git/',
	    },
	},
	provides => Module::Metadata->provides(version => '1.4',
					       dir => 'lib')
    }    
);

unless (eval { symlink("",""); 1 }) {
    if ($^O eq 'MSWin32') {
	$makefile_args{PREREQ_PM}{'Win32API::File'} = 0.1203;
    }
}

WriteMakefile(%makefile_args);

    
