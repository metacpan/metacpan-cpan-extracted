use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'GraphQL::Plugin::Convert::MojoPubSub',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/GraphQL/Plugin/Convert/MojoPubSub.pm',
  ABSTRACT_FROM    => 'lib/GraphQL/Plugin/Convert/MojoPubSub.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.014',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '7.10',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.98',
    'Mojolicious::Plugin::GraphQL' => '0.16', # keepalive
    'Test::Snapshot' => '0.02', # better snapshot filenames
  },
  PREREQ_PM => {
    'GraphQL' => '0.40', # subscriptions
  },
  clean => { FILES => 'GraphQL-Plugin-Convert-MojoPubSub-*' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:graphql-perl/GraphQL-Plugin-Convert-MojoPubSub.git',
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub',
      },
      bugtracker  => {
        web => 'https://github.com/graphql-perl/GraphQL-Plugin-Convert-MojoPubSub/issues',
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
      test => {
        recommends => {
          'Mojo::Redis' => '3.24',
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
