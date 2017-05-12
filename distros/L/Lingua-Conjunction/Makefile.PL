use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	   => 'Lingua::Conjunction',
    'VERSION_FROM' => 'Conjunction.pm',
    'PREREQ_PM'		=> {},
  ($] ge '5.005') ? (
    'AUTHOR'   => 'Robert Rothenberg (rrwo@cpan.org), Damian Conway <damian@csse.monash.edu.au>',
    'ABSTRACT' => 'Convert Perl lists into linguistic conjunctions',
  ) : (),
);
