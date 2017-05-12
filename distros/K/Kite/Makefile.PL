use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'	   => 'Kite',
    'VERSION_FROM' => 'lib/Kite.pm',
    'EXE_FILES'    => [ 'bin/okprof', 'bin/okxml2ps' ],
    'PMLIBDIRS'    => [ 'lib' ], 
    'dist'         => {
	'COMPRESS' => 'gzip',
	'SUFFIX'   => 'gz',
    },
);

