# vim: ts=8
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile (

	# package distribution
	NAME                       => 'Linux::InitFS',
	LICENSE                    => 'lgpl_2_1',
	VERSION_FROM               => 'lib/Linux/InitFS.pm',

	# send flames to...
	AUTHOR                     => 'Kevin Cody-Little <kcody@cpan.org>',

	# source location
	META_MERGE                 => {
		resources          => {
			repository => 'https://github.com/kcodyjr/kcody-perl',
		},
	},

	# dist info
	PREREQ_PM                  => {
		'Cwd'              => 0,
		'Exporter'         => 0,
		'File::ShareDir'   => 0
	},
	dist                       => {
		COMPRESS           => 'gzip',
		SUFFIX             => 'gz'
	},

	# executable hook for kernel build
	INSTALLSCRIPT              => '/usr/libexec',
	INSTALLSITESCRIPT          => '/usr/libexec',
	INSTALLVENDORSCRIPT        => '/usr/libexec',
	EXE_FILES                  => [ 'gen_init_cpio_spec' ]

);

package MY;
use File::ShareDir::Install qw( postamble );
