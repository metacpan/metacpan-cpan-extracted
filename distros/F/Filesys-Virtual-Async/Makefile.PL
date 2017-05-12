#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'			=> 'Filesys::Virtual::Async',
    'VERSION_FROM'	=> 'Async.pm', # finds $VERSION
    'LICENSE'       => 'perl',
    'PREREQ_PM'		=> {
        'Carp'                          => undef,
    },
	'dist'         => {
		'SUFFIX'       => '.gz',
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => 'gzip -9vf',
	},
    ( $] >= 5.005 ? (
        ABSTRACT_FROM   => 'Async.pm',
		AUTHOR          => 'David Davis <xantus@cpan.org>'
      ) : ()
    ),
);
