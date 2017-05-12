use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Math::LP',
    ($] > 5.004) ? (
      'ABSTRACT'  => 'OO interface to linear programs',
      'AUTHOR'    => 'Wim Verhaegen <wimv@cpan.org>',
    ) : (),
    'PREREQ_PM'    => { 
	'Math::LP::Solve'         => '3.02', # wrapper around the solver algorithm
	'Math::LinearCombination' => '0.01', # for setting up constraints
	'Math::SimpleVariable'    => '0.01', # for representing variables
     },
    'VERSION_FROM' => 'lib/Math/LP.pm', 
    'clean'        => {
	FILES => '*/*/*/*~ */*/*/*/*~ */*/*/*/*/*~ */*/*/*/*/*/*~'
     },
    'dist'         => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Math-LP-$(VERSION_SYM)' 
     }, 
);

