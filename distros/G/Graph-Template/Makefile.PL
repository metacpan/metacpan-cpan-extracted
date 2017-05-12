use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Graph::Template',
    VERSION_FROM => 'lib/Graph/Template.pm', # finds $VERSION
    AUTHOR       => 'Rob Kinyon (rkinyon@columbus.rr.com)',
    ABSTRACT     => 'Graph::Template',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'IO::File' => 0.01,
                     'File::Basename' => 0.01,
                     'GD::Graph' => 0.01,
                     'XML::Parser' => 0.01,
                    },
);
