use strict;
use warnings;
use ExtUtils::MakeMaker;

my $repo = 'graphviz-perl/GraphViz2-Data-Grapher';
WriteMakefile(
  AUTHOR => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => "Use GraphViz2 to visualize Perl data structures",
  MIN_PERL_VERSION => 5.010001,
  NAME => 'GraphViz2::Data::Grapher',
  PREREQ_PM => {
    'GraphViz2' => '2.48',
    'Moo' => '2.001001',
    'HTML::Entities::Interpolate' => 1.04,
    'Scalar::Util' => 1.23,
    'Tree::DAG_Node' => 1.06,
  },
  TEST_REQUIRES => {
    'Test::More' => 1.001002,
    'Test::Snapshot' => '0.06',
    'XML::Bare' => 0,
    'File::Slurp' => 9999.19,
  },
  VERSION_FROM => 'lib/GraphViz2/Data/Grapher.pm',
  LICENSE => 'perl',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      dynamic_config => 0,
      bugtracker => { web => "https://github.com/$repo/issues" },
      license => 'http://dev.perl.org/licenses/',
      repository => {
        type => 'git',
        url => "https://github.com/$repo.git",
        web => "https://github.com/$repo",
      },
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => 1.48,
          'Pod::Markdown' => 0,
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
