use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'GD::Graph::histogram',
    VERSION_FROM => 'lib/GD/Graph/histogram.pm', # finds $VERSION
    AUTHOR       => 'William Miller & Snehanshu Shah (perl@whizdog.com)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'GD::Graph' => 1.38
                    },
);
