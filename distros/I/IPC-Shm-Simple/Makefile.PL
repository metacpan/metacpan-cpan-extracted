use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE		=> {
	resources	=> {
	    repository	=> 'https://github.com/kcodyjr/ipcshm-simple',
	},
    },

    NAME		=> 'IPC::Shm::Simple',
    AUTHOR		=> 'Kevin Cody-Little <kcody@cpan.org>',
    LICENSE		=> 'perl',

    VERSION_FROM	=> 'Simple.pm', # finds $VERSION
    ABSTRACT_FROM	=> 'Simple.pm',
    PERL_MALLOC_OK	=> 1,

    OBJECT		=> 'sharelite.o sharelite_shm.o Simple.o',

    PREREQ_PM		=> {
	Carp		=> 0,
	DynaLoader	=> 0,
	Fcntl		=> 0,
	UNIVERSAL	=> 0,
	'Class::Attrib'	=> '1.06',
	'IPC::SysV'	=> 0,
    },

    'dist'		=> {
	COMPRESS	=> 'gzip',
	SUFFIX		=> 'gz',
    },

);
