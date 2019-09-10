use 5.008;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use English;

# minimum required version of dependancies we need to build
our %build_reqs = ( 'libsane' => '1.0.19', );

# minimum required version of dependancies we need to run
our %runtime_reqs = ( 'libsane' => '1.0.19', );

# Can't assume ExtUtils::PkgConfig will return anything useful until
# the pkg-config files ship with sane.
my $lib = '-lsane';
my $inc = '-I. ';
if (
    eval {
        %pkgcfg = ExtUtils::PkgConfig->find(
            'sane-backends >= ' . $build_reqs{libsane} );
    }
  )
{
    $lib = $pkgcfg{libs};
    $inc .= $pkgcfg{cflags};
    $runtime_reqs{libsane} = $pkgcfg{modversion};
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Image::Sane',
    VERSION_FROM => 'lib/Image/Sane.pm',                        # finds $VERSION
    PREREQ_PM    => { Readonly => 0, Exception::Class => 0 },
    CONFIGURE_REQUIRES => {
        ExtUtils::Depends   => 0,
        ExtUtils::PkgConfig => 0
    },
    TEST_REQUIRES => {
        Test::More     => 0,
        Test::Requires => 0,
        Try::Tiny      => 0,
    },
    clean => { FILES => '$(SOURCE_TIDY)' },

    # CPAN doesn't recognise .xz compression
    # dist  => { COMPRESS => 'xz -9', SUFFIX => '.xz', },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Image/Sane.pm',    # retrieve abstract from module
            AUTHOR => 'Jeffrey Ratcliffe'
          )
        : ()
    ),
    LIBS    => [$lib],  # e.g., '-lm'
    CCFLAGS => '-Wall',
    DEFINE  => '',      # e.g., '-DHAVE_SOMETHING'
    INC     => $inc,    # e.g., '-I. -I/usr/include/other'
                        # Un-comment this if you add C files to link with later:
         # OBJECT            => '$(O_FILES)', # link all the C files too
);

sub MY::postamble {

    # GNU Make extensions that BSD make doesn't like.
    # Author-only stuff, so comment out for non-Linux.
    if ( $OSNAME ne 'linux' ) { return }
    return <<'END';
SHELL = bash
MANIFEST = $(shell cat MANIFEST)
SOURCE = $(filter bin/% examples/% %.pm %.PL %.pl %.t,$(MANIFEST))
SOURCE_TIDY = $(foreach file,$(SOURCE),$(file).tdy)

MANIFEST : $(SOURCE)
	git ls-files | egrep -v '^\.(git|be)' > $@

tidy : MANIFEST $(SOURCE_TIDY)

%.tdy : %
	perltidy $* && if ! diff -q $@ $* > /dev/null; then cp $@ $*; fi
END
}
