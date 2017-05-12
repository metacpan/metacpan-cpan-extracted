use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Java::JVM::Classfile',
    'VERSION_FROM'	=> 'lib/Java/JVM/Classfile.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Test::Simple' => 0, 'Class::Struct' => 0 },
    'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
