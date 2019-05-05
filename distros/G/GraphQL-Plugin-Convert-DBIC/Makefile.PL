use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'GraphQL::Plugin::Convert::DBIC',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/GraphQL/Plugin/Convert/DBIC.pm',
  ABSTRACT_FROM    => 'lib/GraphQL/Plugin/Convert/DBIC.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
    'DBIx::Class::Schema' => 0,
    'DBD::SQLite' => 0,
    'Test::Snapshot' => '0.05',
    'JSON::MaybeXS' => 0,
  },
  PREREQ_PM => {
    'DBIx::Class::Schema' => 0,
    'GraphQL' => '0.34', # List->name
    'SQL::Translator' => '0',
    'Lingua::EN::Inflect::Number' => '0',
  },
  clean => { FILES => 'GraphQL-Plugin-Convert-DBIC-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/GraphQL-Plugin-Convert-DBIC.git',
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-DBIC',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-DBIC/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::Pod' => '1.22',
          'Pod::Markdown' => 0,
        },
      },
    },
  },
);

sub MY::postamble {
  <<EOF;
pure_all :: README.md

README.md : \$(VERSION_FROM)
\tpod2markdown \$< >\$\@
EOF
}
