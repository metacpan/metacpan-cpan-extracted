use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	=> 'IO::Events',
    'VERSION_FROM' => 'Events.pm', 
    'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },

    'DISTNAME' => 'IO-Events',
    'ABSTRACT' => 'Events for non-blocking IPC',
    'AUTHOR'   => 'Dmitry Karasik <dmitry@karasik.eu.org>',
    'PREREQ_PM'   => {
        'Time::HiRes' => '0',
    },
);
