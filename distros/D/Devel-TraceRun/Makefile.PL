use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Devel::TraceRun',
  AUTHOR           => q{Ed J <etj@cpan.org>},
  VERSION_FROM     => 'lib/Devel/TraceRun.pm',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => "5.008008",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => '6.63_03',
  },
  "PREREQ_PM" => {
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.92",
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      x_IRC => 'irc://irc.perl.org/#graphql-perl',
      repository => {
        type => 'git',
        url => 'git@github.com:mohawk2/Devel-TraceRun.git',
        web => 'https://github.com/mohawk2/Devel-TraceRun',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/Devel-TraceRun/issues',
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
