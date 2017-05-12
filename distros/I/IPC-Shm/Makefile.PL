use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME			=> 'IPC::Shm',
    AUTHOR			=> 'Kevin Cody-Little <kcodyjr@gmail.com>',
    LICENSE			=> 'perl',

    VERSION_FROM		=> 'IPC/Shm.pm', # finds $VERSION
    ABSTRACT_FROM		=> 'IPC/Shm.pm',
    PERL_MALLOC_OK		=> 1,

    PREREQ_PM			=> {
    	Carp			=> 0,
	Storable		=> 0,
	UNIVERSAL		=> 0,
	'Class::Attrib'		=> 1.06,
	'Digest::SHA1'		=> 0,
	'IPC::Shm::Simple'	=> 1.10,
	'Scalar::Util'		=> 0,
    },

    dist			=> {
     	COMPRESS		=> 'gzip',
	SUFFIX  		=> 'gz',
    },          

);
