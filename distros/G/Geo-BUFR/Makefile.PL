use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
     NAME               => 'Geo::BUFR',
     VERSION_FROM       => 'lib/Geo/BUFR.pm', # finds $VERSION
     PREREQ_PM          => {Carp => 0,
                            Config => 0,
                            DynaLoader => 0,
                            FileHandle => 0,
                            File::Spec::Functions => 0,
                            Getopt::Long => 0,
                            Pod::Usage => 0,
                            Scalar::Util => 0,
                            Storable => 0,
                            Test::More => 0,
                            Time::Local => 0,
                        }, # e.g., Module::Name => 1.1
     EXE_FILES         => ['bufrread.pl',
                           'bufrencode.pl',
                           'bufr_reencode.pl',
                           'bufrresolve.pl',
                           'bufralter.pl',
                           'bufrextract.pl'],
     ABSTRACT_FROM     => 'lib/Geo/BUFR.pm', # retrieve abstract from module
     AUTHOR            => 'P.Sannes <pal.sannes@met.no>',
);
