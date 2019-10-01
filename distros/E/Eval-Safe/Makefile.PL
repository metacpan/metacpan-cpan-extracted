use 5.022;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Eval::Safe',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/Eval/Safe.pm',
    ABSTRACT         => 'Simplified safe evaluation of Perl code',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'File::Spec::Functions' => 0,
        'List::Util'            => 0,
        'Safe'                  => 0,
        'Scalar::Util'          => 0,
    },
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        # Ignores child of Eval::Safe, but not Eval::Safe itself.
        namespace => [ 'Eval::Safe' ],
      },  
      prereqs => {
        # build, test, runtime; suggests, recommands, requires
        test => {
          suggests => {
            'Test::Pod'   => 1.22,
          },
          requires => {
           'Scalar::Util' => 0,
          },
        },
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/perl-eval-safe.git',
          web => 'https://github.com/mkende/perl-eval-safe',
        },
        bugtracker => {
          web => 'https://github.com/mkende/perl-eval-safe/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'eval-safe-*' },
);
