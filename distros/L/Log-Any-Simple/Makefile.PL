# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

## no critic (Policy)

use 5.022;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'Log::Any::Simple',
    DISTNAME         => 'Log-Any-Simple',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/Log/Any/Simple.pm',
    ABSTRACT         => q{A very thin wrapper around Log::Any, using a functional interface that dies automatically when you log above a given level.},
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.022',
    MAN3PODS         => {},
    # Directories in which we look for Makefile.PL. In general could be omitted but is needed in case there
    # is a file named Makefile.PL in a sub-directory. Should be customized if such a file needs to be
    # processed by ExtUtils.
    DIR              => [],
    NO_MYMETA => 1,
    META_MERGE => {
      'meta-spec' => { version => 2 },
      # Goes with NO_MYMETA (which would provide the dynamic config).
      dynamic_config => 0,
      no_index => {
        directory => [ 'local', 'vendor', 't' ],
      },
      keywords => ['Log::Any','log','functional','carp','die',],
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/perl_log_any_simple.git',
          web => 'https://github.com/mkende/perl_log_any_simple',
        },
        bugtracker => {
          web => 'https://github.com/mkende/perl_log_any_simple/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean => { FILES => 'Log-Any-Simple-*' },
);

sub MY::postamble {
  my ($self) = @_;

  my @postamble;
  push @postamble, ::postamble() if *::postamble{CODE};

  # Solaris has a weird (?) make that does not support our `export` statements.
  push @postamble, <<"MAKE_FRAGMENT" unless $^O eq 'solaris';
distupload: distcheck disttest
\t\$(MAKE) tardist
\tcpan-upload --directory Dist-Setup \$(DISTVNAME).tar\$(SUFFIX)

cover:
\tcover -test

critic: export EXTENDED_TESTING = 1
critic: all
\tperl -Ilib t/001-perlcritic.t 2>&1 | less

rawcritic:
\tperlcritic lib 

tidy:
\tperltidy -b -bext='/' \$(shell find lib -name "*.pm")

spelling: export EXTENDED_TESTING = 1
spelling:
\t\$(PERLRUN) t/001-spelling.t --interactive

alltest: export EXTENDED_TESTING = 1
alltest: test

clean:: clean_coverdb

clean_coverdb:
\trm -fr cover_db
MAKE_FRAGMENT

  return join "\n", @postamble;
}

# You can add below this template a `postamble` sub that returns more content to
# add to the generated Makefile.

# End of the template. You can add custom content below this line.
