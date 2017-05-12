
require 5.006_000;
use strict;
use warnings;
use Carp;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#12345678901234567890123456789012345678901234
#Computes pagerank of all nodes in a graph.

WriteMakefile(
    NAME         => 'Graph::Centrality::Pagerank',
    VERSION_FROM => 'lib/Graph/Centrality/Pagerank.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Computes pagerank of all nodes in a graph.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.14',
                     'Graph' => '0.91',
                    },
    LICENSE      => 'perl',
);
__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'Carp' => '1.16',
                     'strict' => '1.04',
                     'Test::More' => '0.96',
                     'vars' => '1.01',
                     'warnings' => '1.09',

                     # list of installed modules used:
                     'Data::Dump' => '1.17',
                     'Graph' => '0.94',
                     'Graph::Centrality::Pagerank' => '1.05',

                     # list of unknown modules used:
                     '5.006_000' => '0',
                    },