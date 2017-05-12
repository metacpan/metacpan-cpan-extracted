use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::LinearCombination',
    ($] > 5.004) ? ( 
      'ABSTRACT'  => 'sum of variables with a numerical coefficient',
      'AUTHOR'    => 'Wim Verhaegen <wimv@cpan.org>',
    ) : (),
    'VERSION_FROM'	=> 'LinearCombination.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	'Carp'                 => undef,
	'Math::SimpleVariable' => '0.03',
    }, 
    'dist'      => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Math-LinearCombination-$(VERSION_SYM)' 
     }, # support Concurrent source Versioning System
);
