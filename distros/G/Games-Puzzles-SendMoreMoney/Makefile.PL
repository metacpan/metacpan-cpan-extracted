######################################################################
# Makefile.PL for Games::Puzzles::SendMoreMoney
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Games::Puzzles::SendMoreMoney',
    'VERSION_FROM' => 'lib/Games/Puzzles/SendMoreMoney.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Algorithm::FastPermute => 0.07,
        Log::Log4perl          => 1,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Games/Puzzles/SendMoreMoney.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
