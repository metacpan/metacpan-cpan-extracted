

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Graph::Undirected::Components',
    VERSION_FROM => 'lib/Graph/Undirected/Components.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Computes components of undirected graph.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.00',
                     'Test::Simple' => '0.44',
                     'Log::Log4perl' => '1.30',
                     'Sort::External' => '0.18',
                     'Text::CSV' => '1.21',
                     'File::Path' => '2.08',
                     'Time::HiRes' => '1.97',
                    },
);
__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'bytes' => '1.04',
                     'Cwd' => '3.36',
                     'File::Compare' => '1.1006',
                     'File::Copy' => '2.21',
                     'File::Spec' => '3.33',
                     'strict' => '1.04',
                     'Time::HiRes' => '1.9725',
                     'warnings' => '1.12',

                     # list of installed modules used:
                     'File::Slurp' => '9999.19',
                     'Graph::Undirected' => '',
                     'Graph::Undirected::Components' => '0.50',
                     'Graph::Undirected::Components::External' => '0.50',
                     'Log::Log4perl' => '1.35',
                     'Sort::External' => '0.18',
                     'Text::CSV' => '1.21',

                     # list of unknown modules used:
                    },