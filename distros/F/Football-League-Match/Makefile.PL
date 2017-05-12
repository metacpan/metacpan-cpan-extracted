use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Football::League::Match',
    'VERSION_FROM'	=> 'Match.pm',
    'PREREQ_PM'		=> 
		{
			Time::Piece => '1.08',
		}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Stray Toaster <coder@stray-toaster.co.uk>') : ()),
);
