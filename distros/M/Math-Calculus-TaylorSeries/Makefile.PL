use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::Calculus::TaylorSeries',
    'VERSION_FROM'	=> 'TaylorSeries.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		Math::Calculus::Expression => 0.2,
		Math::Calculus::Differentiate => 0.3
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TaylorSeries.pm', # retrieve abstract from module
       AUTHOR     => 'Jonathan Worthington <jonathan@jwcs.net>') : ()),
);
