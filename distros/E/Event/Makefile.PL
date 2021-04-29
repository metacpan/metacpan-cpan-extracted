require 5.008; # 5.006_002 fails

use ExtUtils::MakeMaker;

WriteMakefile(
  TEST_REQUIRES => {
    Test => 1,
  },
  MIN_PERL_VERSION  => 'v5.8.0',
  VERSION_FROM	=> "./lib/Event.pm",
  LICENSE	=> "perl_5",
  NAME      	=> "Event",
  TYPEMAPS       => ['./lib/Event/typemap'],
  INC		=> '-Ic -Ilib/Event',
  H		=> [glob("c/*"), glob("*.h"), "lib/Event/EventAPI.h"],
  clean   	=> {
    FILES => join(" ",
    map { "$_ */$_ */*/$_" } qw(*% *.html *.b[ac]k *.old *.orig))
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/mohawk2/cpan-Event.git',
        web => 'https://github.com/mohawk2/cpan-Event',
      },
      bugtracker  => {
        web => 'https://github.com/mohawk2/cpan-Event/issues',
      },
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
