use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
              'NAME'         => 'Devel::Scooby',
              'VERSION_FROM' => 'Scooby.pm',
              'PREREQ_PM'    => {
                                   'Data::Dumper'   => 0,
                                   'Storable'       => 2.04,
                                   'PadWalker'      => 0.08,
                                   'Crypt::RSA'     => 1.50,
                                   'Socket'         => 0,
                                   'IO::Socket'     => 0,
                                },
             );
