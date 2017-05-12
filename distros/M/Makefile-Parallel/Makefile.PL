use strict;
use warnings;
use ExtUtils::MakeMaker;

`yapp  -m Makefile::Parallel::Grammar -o lib/Makefile/Parallel/Grammar.pm lib/Makefile/Parallel/Grammar.yp`;

WriteMakefile(
    NAME                => 'Makefile::Parallel',
    AUTHOR              => 'Ruben Fonseca <root@cpan.org>',
    VERSION_FROM        => 'lib/Makefile/Parallel.pm',
    ABSTRACT_FROM       => 'lib/Makefile/Parallel.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More'          => '0.63',
                  'Parse::Yapp::Driver' => '1.05',
                  'Clone'               => '0.20',
                  'Proc::Simple'        => '1.21',
                  'Log::Log4perl'       => '1.07',
                  'Date::Parse'         => '2.27',
                  'Time::Interval'      => '1.2',
                  'Time::Piece::ISO'    => '0.10',
                  'GraphViz'            => '2.02',
                  'Time::HiRes'         => '1.550',
                  'Text::Balanced'      => '2.0.0',
                  'Proc::Reliable'      => '1.16',
                  'Digest::MD5'         => '2.36',
    },
    EXE_FILES => [ "examples/pmake" ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Makefile-Parallel-*' },
);


die "YAPP is not in your path (or not working)\n" unless -f 'lib/Makefile/Parallel/Grammar.pm';


sub MY::postamble {
  "
lib/Makefile/Parallel/Grammar.pm: lib/Makefile/Parallel/Grammar.yp
	yapp  -m Makefile::Parallel::Grammar -o lib/Makefile/Parallel/Grammar.pm lib/Makefile/Parallel/Grammar.yp
           ";
}
