use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Lingua::DE::ASCII',
    'VERSION_FROM'	=> 'ASCII.pm', # finds $VERSION
    'LICENSE'	        => 'perl',
    'PREREQ_PM'		=> {
        Test::More => 0,
    }, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : (),
       ABSTRACT   => 
        'Perl extension to convert german umlauts to and from ascii'
      ),
);
