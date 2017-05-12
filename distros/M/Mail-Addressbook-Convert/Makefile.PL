
use ExtUtils::MakeMaker;
    WriteMakefile(
        'NAME'              => 'Mail::Addressbook::Convert',
        'VERSION_FROM'      => 'Convert.pm', # finds $VERSION
        
  	'PREREQ_PM' => {
      	Text::ParseWords => 3.1,
     	},
    );

