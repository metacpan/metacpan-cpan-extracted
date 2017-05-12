use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTML::SimpleParse',
    'VERSION_FROM' => 'lib/HTML/SimpleParse.pm', # finds $VERSION
    'PL_FILES'  => {},
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
);
