use 5.022;
use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME             => 'Math::Numerical',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/Math/Numerical.pm',
    ABSTRACT         => "Algorithms for numerical functions (solver, root findings, etc.)",
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
      'Readonly' => '0',
    },
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
      'Test2::V0'             => 0,
      'Test2::Tools::Compare' => 0,
    },
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      prereqs => {
        tests => {
          suggests => {
            'Perl::Tidy'           => 0,
            'Test::Pod'            => '1.00',
            'Test2::Tools::PerlCritic'   => 0,
          },
        },
      },
      keywords => [ qw(math numerical analysis root solver derivative integral) ],
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/math_numerical.git',
          web => 'https://github.com/mkende/math_numerical',
        },
        bugtracker => {
          web => 'https://github.com/mkende/math_numerical/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Numerical-*' },
);

sub MY::postamble {
  return <<~"MAKE_FRAGMENT"
    critic:
    \tperlcritic lib

    tidy:
    \tperltidy -b lib/Math/Numerical.pm

    spelling:
    \tperl -Ilib t/00-spelling.t --interactive

    alltest:
    \tTEST_AUTHOR=1 make test
    MAKE_FRAGMENT
}
