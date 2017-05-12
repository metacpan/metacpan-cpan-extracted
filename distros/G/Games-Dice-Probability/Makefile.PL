use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Games::Dice::Probability',
    VERSION_FROM      => 'lib/Games/Dice/Probability.pm', # finds $VERSION
    PREREQ_PM         => {
	Parse::RecDescent => 0,			# Used to parse dice expressions
	Math::Symbolic::AuxFunctions => 0,	# Used for fast binomial coefficient calcs
    },

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Dice/Probability.pm', # retrieve abstract from module
       AUTHOR         => 'Jason A. Dour <jad@cpan.org>') : ()),
);
