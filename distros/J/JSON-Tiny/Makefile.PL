## no critic (RCS,VERSION,may require interpolation)

use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $PREREQ_PM = {};
$PREREQ_PM->{'Exporter'} = '5.59' if $] < 5.008004;

WriteMakefile(
  NAME             => 'JSON::Tiny',
  AUTHOR           => q{David Oswald <davido[at]cpan[dot]org>},
  VERSION_FROM     => 'lib/JSON/Tiny.pm',
  ABSTRACT_FROM    => 'lib/JSON/Tiny.pod',
  LICENSE          => 'artistic_2',
  MIN_PERL_VERSION => '5.008000',
  PL_FILES         => {},
  PREREQ_PM        => $PREREQ_PM,
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources   => {
      license     => 'http://www.perlfoundation.org/artistic_license_2_0',
      repository  => {
        type => 'git',
        url  => 'https://github.com/daoswald/JSON-Tiny.git',
        web  => 'https://github.com/daoswald/JSON-Tiny',
      },
    },
    provides => {
      'JSON::Tiny' => {
        file    => 'lib/JSON/Tiny.pm',
        version => '0.56'
      },
    },
    prereqs => {
      runtime => {
        requires => $PREREQ_PM,
        suggests => {'JSON::PP' => '0'},
      },
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  clean => { FILES    => 'JSON-Tiny-*' },
);
