use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Encode::IMAPUTF7',
    'VERSION_FROM' => 'lib/Encode/IMAPUTF7.pm',    
    'dist'          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Encode/IMAPUTF7.pm',
       AUTHOR         => 'Peter Makholm <peter@makholm.net>') : ()),
    PREREQ_PM      => {
        'Encode'           => 0,  # In core since 5.7.3
        'Test::NoWarnings' => 0,
    }
);
