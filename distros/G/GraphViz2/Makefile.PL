use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Temp;

sub is_dot_installed
{
  # 1: Create a temp file containing DOT commands.
  # The EXLOCK option is for BSD-based systems.
  # newdir() croaks() if it fails, which is what we want.
  my($temp_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
  my($gv_file)  = File::Spec -> catfile($temp_dir, 'test.gv');
  open my $fh, ">", $gv_file or die "Can't create temp file: $!\n";
  print $fh "digraph graph_14 {node_14}\n" or die "Can't write to temp file: $!\n";
  close $fh                                or die "Can't close temp file: $!\n";
  # 2: Run dot to create an SVG file.
  my $stdout = `dot -Tsvg $gv_file`;
  # 3: If that failed, we die.
  die "Please install Graphviz from http://www.graphviz.org/\n" if ($stdout !~ m|</svg>|);
} # End of is_dot_installed.

is_dot_installed();

WriteMakefile(
  AUTHOR => 'Ron Savage <ron@savage.net.au>',
  ABSTRACT => "A wrapper for AT&T's Graphviz",
  MIN_PERL_VERSION => 5.008008,
  NAME => 'GraphViz2',
  PREREQ_PM => {
    'Data::Section::Simple' => 0.02,
    'File::Which' => 1.21,
    'IPC::Run3' => 0.048,
    'Moo' => 2.001001,
    'Types::Standard' => 1.000005,
    'Graph' => '0.9716',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
    'Test::Snapshot' => '0.06',
  },
  VERSION_FROM => 'lib/GraphViz2.pm',
  LICENSE => 'perl',
  META_MERGE => {
    'meta-spec' => {
      version => 2,
    },
    dynamic_config => 0,
    resources => {
      bugtracker => { web => 'https://github.com/graphviz-perl/GraphViz2/issues' },
      license => 'http://dev.perl.org/licenses/',
      repository => {
        type => 'git',
        url => 'https://github.com/graphviz-perl/GraphViz2.git',
        web => 'https://github.com/graphviz-perl/GraphViz2',
      },
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => '1.48',
          'Pod::Markdown' => 0,
        },
        suggests => {
          # for generating the website stuff
          'Text::Xslate' => 1.2000,
          'HTTP::Tiny' => 0.012,
          'HTML::TreeBuilder' => 4.2,
          'Date::Simple' => 3.03,
          'Config::Tiny' => 2.16,
          'File::HomeDir' => 0.99,
        },
      },
    },
  },
);

sub MY::postamble {
  return '' if !-e '.git';
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
