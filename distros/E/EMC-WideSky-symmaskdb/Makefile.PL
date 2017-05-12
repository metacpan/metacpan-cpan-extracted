use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'EMC::WideSky::symmaskdb',
    'VERSION_FROM' => 'symmaskdb.pm', # finds $VERSION
    'PREREQ_PM' => { 'XML::Parser' => '2.31' },
    'EXE_FILES' => [ map "bin/$_", ( 'vcmshow' ) ],
    dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', }


);
