use ExtUtils::MakeMaker;        # See the Camel, page 409-
require 5.004;
$Verbose = 1;

WriteMakefile(
              'NAME'            => 'Interval',
              'VERSION_FROM'    => 'Interval.pm',
              'clean'           => {'FILES' => 'err'},
              'dist'            => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

