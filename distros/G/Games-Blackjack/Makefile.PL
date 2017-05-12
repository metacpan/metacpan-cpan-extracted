######################################################################
# Makefile.PL for Games::Blackjack
# 2003, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Games::Blackjack',
    'VERSION_FROM' => 'lib/Games/Blackjack.pm', # finds $VERSION
    'PREREQ_PM'    => { Quantum::Superpositions => undef,
                        Algorithm::GenerateSequence => undef,
                        Algorithm::Numerical::Shuffle => undef,
                        Log::Log4perl => undef,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Games/Blackjack.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
