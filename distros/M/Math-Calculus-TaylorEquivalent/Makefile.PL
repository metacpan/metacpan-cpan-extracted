use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Calculus::TaylorEquivalent',
    'VERSION_FROM'	=> 'TaylorEquivalent.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Math::Calculus::TaylorSeries => 0.1
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TaylorEquivalent.pm', # retrieve abstract from module
       AUTHOR     => 'Jonathan Worthington <jonathan@jwcs.net>') : ()),
);
