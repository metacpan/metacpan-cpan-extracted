use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Temp;
use File::Spec;

sub is_dot_installed { #_{


	my $temp_dir = File::Temp->newdir(
   'temp.XXXX',
    CLEANUP => 1,
    EXLOCK  => 0,  # For BSD based systems
    TMPDIR  => 1
  );

  my $dot_file = File::Spec->catfile($temp_dir, 'is_dot_installed.dot');

  open (my $dot_file_fh, '>', $dot_file) or die "Could not open $dot_file";
  print $dot_file_fh "digraph is_dot_installed { node_1 }\n";
  close $dot_file_fh;

  my $dot_out = readpipe("dot -Tsvg $dot_file 2>&1") // '';

  return $dot_out =~ m|</svg>|;
} #_}

die "Please install Graphviz from http://www.graphviz.org/\n" unless is_dot_installed();

WriteMakefile(
    NAME             => 'GraphViz::Graph',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/GraphViz/Graph.pm',
    ABSTRACT_FROM    => 'lib/GraphViz/Graph.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Exception'   => 0,
        'Test::Files'       => 0,
        'Test::More'        => 0,
        'Test::Simple'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'GraphViz-Graph-*' },
);
