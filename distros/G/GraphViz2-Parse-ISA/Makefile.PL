use strict;
use warnings;
use ExtUtils::MakeMaker;

my $repo = 'graphviz-perl/GraphViz2-Parse-ISA';
WriteMakefile(
  AUTHOR => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => "Use GraphViz2 to visualize Perl class hierarchies",
  MIN_PERL_VERSION => 5.008008,
  NAME => 'GraphViz2::Parse::ISA',
  PREREQ_PM => {
    'GraphViz2' => '2.48',
    'Moo' => '2.001001',
    'Module::Runtime' => '0.016',
    'parent' => 0, # not in 5.8
  },
  TEST_REQUIRES => {
    'Test::More' => 1.001002,
    'Test::Snapshot' => '0.06',
  },
  VERSION_FROM => 'lib/GraphViz2/Parse/ISA.pm',
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
