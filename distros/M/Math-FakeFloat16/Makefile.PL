use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

my $defines = $Config::Config{byteorder} =~ /^1234/ ? " -DWE_HAVE_LENDIAN" : " -DWE_HAVE_BENDIAN";

my %options = (
  NAME         => 'Math::FakeFloat16',
  AUTHOR       => 'Sisyphus (sisyphus at (@) cpan dot (.) org)',
  ABSTRACT     => "C's  _Float16 arithmetic using Math::MPFR objects",
  LICENSE      => 'perl',
  VERSION_FROM => 'FakeFloat16.pm',
  DEFINE       => $defines,
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-float16.git',
        web          => 'https://github.com/sisyphus/math-float16',
      },
    },
  },
);

my $prereq =  { 'Test::More' => '0.88',
                'Exporter'   => '5.58',
                'Math::MPFR' => '4.44',
              };

$options{PREREQ_PM} = $prereq;

WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
