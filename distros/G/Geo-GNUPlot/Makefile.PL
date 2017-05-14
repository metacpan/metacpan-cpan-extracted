use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'	=> 'Geo-Plot',
	'VERSION_FROM' => 'lib/Geo/GNUPlot.pm', # finds $VERSION
	'PREREQ_PM' => {
                        'IO::File' => 1.08,
                        },
        'dist'  => {
                'PREOP' => q{(echo "hi jimmy";echo "isn't this fun";)},
                'COMPRESS' => 'gzip',
                'SUFFIX' => 'gz',
        },


);
