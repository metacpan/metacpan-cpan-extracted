use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'GraphQL::Plugin::Convert::OpenAPI',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/GraphQL/Plugin/Convert/OpenAPI.pm',
  ABSTRACT_FROM    => 'lib/GraphQL/Plugin/Convert/OpenAPI.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
    'JSON::Validator' => '2.01', # fqn bundle fix
    'GraphQL' => '0.26', # promises
    'OpenAPI::Client' => '0.17', # "call_p" interface
    'YAML::XS' => '0.68', # local.t needs, <0.68 breaks
    'Mojolicious::Plugin::GraphQL' => '0.11', # Promise->all class method
    'Mojolicious::Plugin::OpenAPI' => '1.25', # register returns plugin
    'Test::Snapshot' => '0.02', # better snapshot filenames
  },
  PREREQ_PM => {
    'JSON::Validator' => '2.01', # fqn bundle fix
    'GraphQL' => '0.26', # promises
    'OpenAPI::Client' => '0.17', # "call_p" interface
  },
  clean => { FILES => 'GraphQL-Plugin-Convert-OpenAPI-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/GraphQL-Plugin-Convert-OpenAPI.git',
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-OpenAPI',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-OpenAPI/issues',
      },
      license => [ 'http://dev.perl.org/licenses/' ],
    },
    prereqs => {
      develop => {
        requires => {
          'Test::CheckManifest' => '0.9',
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

README.md : lib/GraphQL/Plugin/Convert/OpenAPI.pm
\tpod2markdown \$< >\$\@
EOF
}
