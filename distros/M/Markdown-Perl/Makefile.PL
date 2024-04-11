# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

## no critic (Policy)

use 5.026;
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME             => 'Markdown::Perl',
    DISTNAME         => 'Markdown-Perl',
    AUTHOR           => q{Mathias Kende <mathias@cpan.org>},
    VERSION_FROM     => 'lib/Markdown/Perl.pm',
    ABSTRACT         => q{Very configurable Markdown processor written in pure Perl, supporting the CommonMark spec and many extensions},
    LICENSE          => 'mit',
    EXE_FILES        => ['script/pmarkdown',],
    MIN_PERL_VERSION => '5.026',
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
        directory => [ 'local', 'vendor' ],
      },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:mkende/pmarkdown.git',
          web => 'https://github.com/mkende/pmarkdown',
        },
        bugtracker => {
          web => 'https://github.com/mkende/pmarkdown/issues',
        },
      },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean => { FILES => 'Markdown-Perl-*' },
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
\tperlcritic lib script

tidy:
\tperltidy -b -bext='/' \$(shell find lib -name "*.pm") script/pmarkdown

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

sub postamble {
  return if $^O eq 'solaris';
  return <<"EOF";
profile:
\t-perl -Ilib -d:NYTProf t/900-cmark-test-suite.t --fast
\tnytprofhtml
\t\@echo Profile is at `pwd`/nytprof/index.html

clean:: clean_nytprof

clean_nytprof:
\trm -fr nytprof nytprof.out

exe: build build/pmarkdown\$(EXE_EXT)

build:
\tmkdir -p build

.PHONY: build/pmarkdown\$(EXE_EXT)
build/pmarkdown\$(EXE_EXT): export PAR_VERBATIM=1
build/pmarkdown\$(EXE_EXT):
\tpp -o build/pmarkdown\$(EXE_EXT) -cd build/pp.cache -I lib -F "PodStrip=.*\\bMarkdown/Perl\\b(*COMMIT)(*FAIL)|.*" script/pmarkdown

test: export HARNESS_OPTIONS = j8:c

fuzzing: export MAXI_TEST = 1
fuzzing:
\tperl -Ilib t/801-fuzzing.t

EOF
}
