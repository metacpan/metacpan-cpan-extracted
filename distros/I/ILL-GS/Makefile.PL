use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Biblio::ILL::GS',
    'DISTNAME'		=> 'ILL-GS',
    'VERSION_FROM'	=> 'lib/Biblio/ILL/GS.pm', 
    'ABSTRACT'          => 'Interlibrary Loan Generic Script (GS)',
    'AUTHOR'		=> 'David Christensen <DChristensen@westman.wave.ca>',
    'PMLIBDIRS'		=> [ qw( lib/ ) ],
    'PREREQ_PM'		=> { 'Test::More' => 0 }
);
