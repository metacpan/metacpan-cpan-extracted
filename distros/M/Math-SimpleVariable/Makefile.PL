use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Math::SimpleVariable',
    ($] > 5.004) ? ( 
      'ABSTRACT'  => 'simple representation of mathematical variables',
      'AUTHOR'    => 'Wim Verhaegen <wimv@cpan.org>',
    ) : (),
    'VERSION_FROM'	=> 'SimpleVariable.pm', # finds $VERSION
    'PREREQ_PM'		=> {Carp => undef}, 
    'dist'      => { 
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Math-SimpleVariable-$(VERSION_SYM)' 
     }, # support Concurrent source Versioning System
);
