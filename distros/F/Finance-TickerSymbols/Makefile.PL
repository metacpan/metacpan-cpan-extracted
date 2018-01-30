
use ExtUtils::MakeMaker;

WriteMakefile

  ( NAME              => 'Finance::TickerSymbols',
    VERSION_FROM      => 'lib/Finance/TickerSymbols.pm',
    PREREQ_PM         => { LWP => 6.00,
                           LWP::Protocol::https => 6.00
                         },
    LICENSE           => perl =>
    ABSTRACT_FROM  => 'lib/Finance/TickerSymbols.pm',
    AUTHOR         => 'Josef Ezra <jezra@cpan.org>'
  );
