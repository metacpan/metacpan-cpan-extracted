require 5.004;

use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'	   => 'Lingua::EN::NameLookup',
    'VERSION_FROM' => 'NameLookup.pm',
    'PREREQ_PM'    => {	
	                 'Text::Soundex' => 2.00,
		      },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
