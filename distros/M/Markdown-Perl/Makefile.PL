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
        directory => [ 'local', 'vendor', 't' ],
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

# These platforms (usually) have GNU Make by default so the syntax that we use
# for our custom targets below will work (especially to export environment
# variables).
# On other platforms, we disable the custom parts of our Makefile generation, as
# the generated Makefile would otherwise not parse correctly.
sub supported_platform {
  return $^O =~ m/^(?:linux|cygwin|MSWin32)$/;
}

sub MY::postamble {
  my ($self) = @_;

  my @postamble;
  push @postamble, ::postamble() if *::postamble{CODE};

  push @postamble, <<"MAKE_FRAGMENT" if supported_platform();
ALL_PM := \$(shell find lib -name "*.pm")
ALL_EXE := script/pmarkdown

.PHONY: distupload cover critic rawcritic tidy spelling alltest clean clean_coverdb pod2html exe

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
\tperltidy -b -bext='/' \$(ALL_PM) \$(ALL_EXE)

spelling: export EXTENDED_TESTING = 1
spelling:
\t\$(PERLRUN) t/001-spelling.t --interactive

test: export HARNESS_OPTIONS = j8:c

alltest: export EXTENDED_TESTING = 1
alltest: test

clean:: clean_coverdb clean_build clean_pod2html

clean_coverdb:
\trm -fr cover_db

clean_build:
\trm -fr build

clean_pod2html:
\trm -fr pod2html

PM_HTML := \$(patsubst %.pm, pod2html/%.html, \$(ALL_PM))
EXE_HTML := \$(patsubst %, pod2html/%.html, \$(ALL_EXE))
pod2html: \$(PM_HTML) \$(EXE_HTML)

\$(PM_HTML): pod2html/%.html: %.pm
\tmkdir -p \$(shell dirname \$@)
\tpod2html --infile \$< --outfile \$@

\$(EXE_HTML): pod2html/%.html: %
\tmkdir -p \$(shell dirname \$@)
\tpod2html --infile \$< --outfile \$@

EXE_EXE := \$(patsubst %, build/%\$(EXE_EXT), \$(ALL_EXE))

exe: export PAR_VERBATIM=1
exe: build \$(EXE_EXE)

build:
\tmkdir -p build

\$(EXE_EXE): build/%\$(EXE_EXT): %
\tpp -o \$@ -cd build/pp.cache -I lib -F "PodStrip=.*\\bMarkdown/Perl\\b(*COMMIT)(*FAIL)|.*" \$<

MAKE_FRAGMENT

  return join "\n", @postamble;
}

# You can add below this template a `postamble` sub that returns more content to
# add to the generated Makefile.

# End of the template. You can add custom content below this line.

sub postamble {
  return unless supported_platform();
  return <<"EOF";
profile:
\t-perl -Ilib -d:NYTProf t/900-cmark-test-suite.t --fast
\tnytprofhtml
\t\@echo Profile is at `pwd`/nytprof/index.html

clean:: clean_nytprof

clean_nytprof:
\trm -fr nytprof nytprof.out

fuzzing: export MAXI_TEST = 1
fuzzing:
\tperl -Ilib t/801-fuzzing.t

EOF
}
