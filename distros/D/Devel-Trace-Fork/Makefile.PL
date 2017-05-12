use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Trace::Fork',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Devel/Trace/Fork.pm',
    ABSTRACT_FROM       => 'lib/Devel/Trace/Fork.pm',
    ($ExtUtils::MakeMaker::VERSION+0 >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Devel::Trace' => '0.10'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => join ' ',
			                 'Devel-Trace-Fork-*',
			                 'DTFork.*',
			                 't/01-testprog.*'},
);
