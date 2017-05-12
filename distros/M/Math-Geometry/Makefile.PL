use ExtUtils::MakeMaker;
my $module = 'Geometry.pm';
WriteMakefile(
              NAME         => 'Math::Geometry',
              VERSION_FROM => $module,
              PREREQ_PM    => {
                               Test::More => 0,
                               Math::Matrix => 0
                              },
              AUTHOR       => 'Greg McCarroll <greg@mccarroll.org.uk>',
             );


