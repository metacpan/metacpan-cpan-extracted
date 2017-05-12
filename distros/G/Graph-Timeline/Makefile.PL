use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Graph::Timeline',
    VERSION_FROM => 'lib/Graph/Timeline.pm',
    EXE_FILES    => [ ],
    PREREQ_PM    => { 
						'Date::Calc' => 0, 
   						'GD' => 0,
						'GD::Text' => 0,
						'GD::Text::Wrap' => 0,
					},
);
