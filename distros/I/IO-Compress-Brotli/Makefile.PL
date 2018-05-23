use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'IO::Compress::Brotli',
	VERSION_FROM     => 'lib/IO/Compress/Brotli.pm',
	ABSTRACT         => 'Read/write Brotli buffers/streams',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	EXE_FILES        => [ 'bin/bro-perl' ],
	PREREQ_PM        => {
		'File::Slurper' => '0',
		'Getopt::Long'  => '0',
		'Time::HiRes'   => '0',
	},
	BUILD_REQUIRES   => {},
	INC              => '-Ibrotli/c/include',
	MYEXTLIB         => 'brotli/libbrotli$(LIB_EXT)',
	clean            => { FILES => 'brotli/libbrotli$(LIB_EXT)' },
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=io-compress-brotli.git',
		},
	}
);

sub MY::postamble {
'
$(MYEXTLIB): brotli/Makefile
	cd brotli && CFLAGS=-fPIC `which gmake || echo $(MAKE)` lib
'
}
