use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Iss::Ah::Predictor',
  VERSION_FROM => 'lib/ISS/AH/Predictor.pm',
  ABSTRACT     => 'ISS AH Predictor',
  AUTHOR       => 'Christoph Beger <christoph.beger@medizin.uni-leipzig.de>',
  LICENSE      => 'MIT',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => { version   => 2 },
    no_index       => { directory => [qw(t)], },
    prereqs        => { runtime   => { requires => { perl => '5.006' } } },
    resources      => {
      bugtracker => { web => 'https://github.com/CrescNet/iss-ah-predictor/issues' },
      license    => ['https://opensource.org/licenses/MIT'],
      repository => {
        type => 'git',
        url  => 'https://github.com/CrescNet/iss-ah-predictor.git',
        web  => 'https://github.com/CrescNet/iss-ah-predictor',
      },
    },
  },
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '7.24' },
  TEST_REQUIRES      => {
    'Test::More'     => '1.3',
    'Test::PerlTidy' => '20200411',
  },
  PREREQ_PM => { 'Scalar::Util' => '1.4602' },
  test      => { TESTS          => 't/*.t t/*/*.t' },
  dist      => { COMPRESS       => 'gzip -9f', SUFFIX => 'gz', },
  clean     => { FILES          => 'Iss-Ah-Predictor-*' },
);
