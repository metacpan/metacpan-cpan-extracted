
use ExtUtils::MakeMaker;

WriteMakefile

  ( NAME              => 'Finance::TickerSymbols',
    VERSION_FROM      => 'lib/Finance/TickerSymbols.pm',
    PREREQ_PM         => { LWP => 5.00
                         },
    LICENSE           => perl =>
    ABSTRACT_FROM  => 'lib/Finance/TickerSymbols.pm',
    AUTHOR         => 'Josef Ezra <jezra@cpan.org>'
  );
