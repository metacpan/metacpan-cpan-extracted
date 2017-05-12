use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME		=> 'Devel::CCov',
	      PREREQ_PM		=> { Bit::Vector => '5.0',
				     Storable => '0.5',
				     Data::Dumper => '2.07', },
	      EXE_FILES		=> [qw(ccovinstrument ccovanalyze)],
#	      OPTIMIZE		=> '-g',
	      VERSION_FROM	=> 'lib/Devel/CCov.pm',
              dist		=> {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
	      );
