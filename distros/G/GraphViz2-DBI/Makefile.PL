use strict;
use warnings;
use ExtUtils::MakeMaker;

my $repo = 'graphviz-perl/GraphViz2-DBI';
WriteMakefile(
  AUTHOR => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => "Use GraphViz2 to visualize a database schema",
  MIN_PERL_VERSION => 5.010001,
  NAME => 'GraphViz2::DBI',
  PREREQ_PM => {
    'GraphViz2' => '2.48',
    'DBIx::Admin::TableInfo' => '3.00',
    'Lingua::EN::PluralToSingular' => '0.14',
    'Moo' => '2.001001',
  },
  TEST_REQUIRES => {
    'Test::More' => 1.001002,
    'DBD::SQLite' => '1.66',
  },
  VERSION_FROM => 'lib/GraphViz2/DBI.pm',
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
        },
      },
    },
  },
);
