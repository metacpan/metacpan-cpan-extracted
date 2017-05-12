use 5.010001;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Jmespath',
  VERSION_FROM  => 'lib/Jmespath.pm',
  ABSTRACT      => 'JMESPath is a query language for JSON.',
  AUTHOR        => 'Richard Elberger <riche@cpan.org>',
  LICENSE       => 'artistic_2',
  INSTALLDIRS   => ($] < 5.011 ? 'perl' : 'site'),
  META_MERGE    => {
    dynamic_config   => 0,
    'meta-spec'      => { version => 2 },
    no_index         => { directory => [ 't' ], },
    prereqs          => {runtime => {requires => {perl => '5.010001'}}},
    resources        => {
      bugtracker  => { web => 'https://github.com/rpcme/jmespath.pl/issues' },
      homepage    => 'http://jmespath.org',
      license     => [ 'http://www.opensource.org/licenses/artistic-license-2.0' ],
      repository  => {
        url  => 'https://github.com/rpcme/jmespath.pl.git',
        web  => 'https://github.com/rpcme/jmespath.pl',
        type => 'git',
      },
    },
  },
  PREREQ_PM => {
    'Try::Tiny'      => 0,
    'File::Slurp'    => 0,
    'Moose'          => 0,
    'JSON'           => 0,
    'Throwable'      => 0,
    'String::Util'   => 0,
    'List::Util'     => "1.46",
  },
  EXE_FILES => [ 'script/jp' ],
  clean     => { FILES => 'cover_db', },
  test      => { TESTS => 't/*.t' },
);
