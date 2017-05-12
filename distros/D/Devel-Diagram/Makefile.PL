
# $Name:  $

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Devel::Diagram',
    'VERSION_FROM' => "lib/Devel/Diagram.pm",
    'PREREQ_PM' => { 
                   },
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD',
                     'ABSTRACT' => 'Discover the classes of an arbitrary suite of Perl modules',
                    ) : (),
);

