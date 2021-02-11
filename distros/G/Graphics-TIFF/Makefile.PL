use strict;
use warnings;
use 5.008;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use English;

# minimum required version of dependancies we need to build
our %build_reqs = ( 'libtiff' => '4.0.3', );

# minimum required version of dependancies we need to run
our %runtime_reqs = ( 'libtiff' => '4.0.3', );

# Can't assume ExtUtils::PkgConfig will return anything useful until
# the pkg-config files ship with libtiff.
my $lib = '-ltiff';
my $inc = '-I. ';
my %pkgcfg;
if (
    eval {
        %pkgcfg =
          ExtUtils::PkgConfig->find( 'libtiff-4 >= ' . $build_reqs{libtiff} );
    }
  )
{
    $lib = $pkgcfg{libs};
    $inc .= $pkgcfg{cflags};
    $runtime_reqs{libtiff} = $pkgcfg{modversion};
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME               => 'Graphics::TIFF',
    VERSION_FROM       => 'lib/Graphics/TIFF.pm',    # finds $VERSION
    PREREQ_PM          => { Readonly => 0 },         # e.g., Module::Name => 1.1
    CONFIGURE_REQUIRES => {
        'ExtUtils::Depends'   => 0,
        'ExtUtils::PkgConfig' => 0
    },
    TEST_REQUIRES => {
        'File::Spec'     => 0,
        'File::Temp'     => 0.19,
        'Test::More'     => 0,
        'Test::Requires' => 0,
        'Test::Deep'     => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/carygravel/graphics-tiff.git',
                web  => 'https://github.com/carygravel/graphics-tiff',
            },
        },
    },
    clean => { FILES => '$(SOURCE_TIDY)' },

    # CPAN does not recognise .xz encoded files
    #    dist  => { COMPRESS => 'xz -9', SUFFIX => '.xz', },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Graphics/TIFF.pm',    # retrieve abstract from module
            AUTHOR => 'Jeffrey Ratcliffe'
          )
        : ()
    ),
    LIBS   => [$lib],   # e.g., '-lm'
    DEFINE => '',       # e.g., '-DHAVE_SOMETHING'
    INC    => $inc,     # e.g., '-I. -I/usr/include/other'
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

tardist : README

README : lib/Graphics/TIFF.pm
	pod2readme $< $@

tidy : MANIFEST $(SOURCE_TIDY)

%.tdy : %
	perltidy $* && if ! diff -q $@ $* > /dev/null; then cp $@ $*; fi
END
}
