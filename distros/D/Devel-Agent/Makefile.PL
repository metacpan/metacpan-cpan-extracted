use 5.34.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::Agent',
    VERSION_FROM      => 'lib/Devel/Agent.pm',
    LICENSE=>'perl_5',
    EXE_FILES=>[ qw() ],
    PREREQ_PM         => {
    qw(
      Data::Dumper 0
      Modern::Perl 0
      Role::Tiny   0
      Moo          0
      AnyEvent     0
    )
    }
);

