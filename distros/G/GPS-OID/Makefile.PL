use ExtUtils::MakeMaker;
WriteMakefile(
  NAME      => q{GPS::OID},
  VERSION_FROM => q{lib/GPS/OID.pm},
  ABSTRACT_FROM => 'lib/GPS/OID.pm',
  PREREQ_PM => {
                 strict            => 0,
                 warnings          => 0,
                 'Test::Simple'    => 0, #Test::More
               },
             );
