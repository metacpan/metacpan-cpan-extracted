use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

eval { require 5.005 };

if ($@ =~ /required/ )
{
	die "Sorry you need perl 5.005 or later\n";
}

WriteMakefile(
    'NAME'	=> 'MMM::Text::Search',
    'VERSION_FROM' => 'Search.pm', # finds $VERSION
    
      clean => {
    	FILES =>  ' .test_pl-* .test_pl.*' 
	}
);
