use 5.026003;
use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Temp ();

# Where the vendored jq is unpacked and built, and the staging prefix it is
# installed into.  Everything here is a build artifact: "make realclean" and
# "make jq_clean" remove it, and nothing under it is installed.
my $JQ_BUILD = '.jq-build';
my $JQ_STAGE = "$JQ_BUILD/stage";

# Linking the libjq the OS packages is still supported, for a packager who
# cannot ship a vendored copy:
#
#   perl Makefile.PL JQ_SYSTEM=1        (or JQ_SYSTEM=1 in the environment)
#
# The argument is deliberately left in @ARGV rather than shifted out of it:
# MakeMaker bakes @ARGV into the Makefile's own "re-run Makefile.PL" rule, so
# removing it here would silently lose the choice if the Makefile were
# regenerated.  The price is one line of MakeMaker chatter --
# "'JQ_SYSTEM' is not a known MakeMaker parameter name." -- which cannot be
# suppressed from out here, because the list it checks against is a lexical
# inside MakeMaker.  It is harmless: the argument is ours, not MakeMaker's.
my $system_jq = $ENV{JQ_SYSTEM} ? 1 : 0;
for (@ARGV) { $system_jq = ($1 ? 1 : 0) if /^JQ_SYSTEM=(.*)\z/ }

my $JQ_TARBALL;
my %jq;
if ($system_jq) {
    # jq's headers carry no version, at build time or at run time, so the only
    # way to find out what the OS libjq implements is to try linking against
    # it.  jq_set_stderr_cb and its getter -- the pair behind the "stderr"
    # builtin -- arrived after the jq 1.6 that RHEL 8 and Debian 11 still ship,
    # and everything else the XS calls has been there since 1.5.
    my $stderr_cb = libjq_has('jq_set_stderr_cb');
    warn <<'END' unless $stderr_cb;
This libjq has no jq_set_stderr_cb (it predates jq 1.7), so JQ::XS is being
built without support for the "stderr" builtin: set_stderr_cb() will croak,
and JQ::XS::features()->{stderr_cb} will be false.  Everything else works.

END

    %jq = (
        INC    => '-I.',
        DEFINE => $stderr_cb ? '-DJQ_XS_HAVE_STDERR_CB' : '',
        LIBS   => ['-ljq'],
    );
}
else {
    # The vendored tarball is the single record of which jq this is: its name
    # carries the version, and build-jq.pl and t/embedded-jq.t both read the
    # version back out of it.  Nothing here repeats it, so upgrading jq is a
    # matter of replacing the file.
    my @tarballs = sort glob 'vendor/jq-*.tar.gz';

    @tarballs or die <<"END";
No vendored jq found (looked for vendor/jq-*.tar.gz).

JQ::XS compiles its own copy of jq rather than linking the one the OS packages,
so the release tarball has to be present.  If this is a checkout with the
tarball removed, restore it; to build against the OS libjq instead, run

    perl Makefile.PL JQ_SYSTEM=1

END

    @tarballs == 1 or die
        "More than one vendored jq in vendor/:\n" .
        join('', map { "    $_\n" } @tarballs) .
        "Leave exactly one, so which jq gets compiled in is unambiguous.\n";

    $JQ_TARBALL = $tarballs[0];

    # $(MYEXTLIB) is the right home for the two static archives: MakeMaker
    # makes it a prerequisite of the shared object and places it on the link
    # line after $(LDFROM), which is what a static archive needs -- it only
    # resolves symbols that objects already on the line refer to.  libjq must
    # also come before libonig, because libjq is what refers to it.  (LIBS
    # cannot carry them: ExtUtils::Liblist only understands -l/-L/-R and
    # discards anything else with a warning.  Nor can dynamic_lib's
    # OTHERLDFLAGS, which MakeMaker emits *before* $(MYEXTLIB).)
    #
    # One caveat, for the record: "make static" copies $(MYEXTLIB) with $(CP)
    # as the starter for its archive, which a two-file value would break.
    # Nothing here builds that way -- perl loads XS objects dynamically.
    %jq = (
        INC      => "-I. -I$JQ_STAGE/include",
        # The vendored jq cannot be probed the way the OS one can -- it is
        # built by "make", long after this runs -- but it does not need to be:
        # the tarball under vendor/ is a known release, and every jq since 1.7
        # has jq_set_stderr_cb.  Worth rechecking when that tarball is bumped
        # backwards, which is the only way this could become untrue.
        DEFINE   => '-DJQ_XS_EMBEDDED -DJQ_XS_HAVE_STDERR_CB',
        MYEXTLIB => "$JQ_STAGE/lib/libjq$Config{lib_ext} " .
                    "$JQ_STAGE/lib/libonig$Config{lib_ext}",
        # What libjq.la records as its dependencies: libm for the math
        # builtins, libpthread for the thread-local dtoa context.  Linking the
        # shared libjq got these for free through DT_NEEDED; a static archive
        # does not, and on a glibc older than 2.34 -- EL8's is 2.28 -- the
        # pthread symbols really do live outside libc.
        LIBS     => ['-lm -lpthread'],
        # Compiling XS.c needs the staged jq.h/jv.h, not just the archives at
        # link time, so the object has to wait for the jq build as well.
        # Without this "make -j" is free to run gcc on XS.c first and fail on
        # the missing headers -- which is exactly what rpmbuild's parallel
        # %build does.
        depend   => { '$(OBJECT)' => "$JQ_STAGE/lib/libjq$Config{lib_ext}" },
        # Symbols pulled out of the two archives have no business being
        # exported from XS.so; there are over 600 of them.  Best-effort: the
        # flag is GNU ld's, and the module links fine without it.
        (ld_accepts('-Wl,--exclude-libs,ALL')
            ? (dynamic_lib => { OTHERLDFLAGS => '-Wl,--exclude-libs,ALL' })
            : ()),
    );
}

# Does the libjq we are about to link define this function?  Compiles and
# links a program that calls it, which is the only way to ask: no header or
# runtime call reports the version.  The call is never executed -- the
# declaration deliberately gives no prototype, so the arguments do not have to
# be known here -- only linked, which is what needs the symbol to exist.
sub libjq_has {
    my ($func) = @_;

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $c   = File::Spec->catfile($dir, 'probe.c');
    my $exe = File::Spec->catfile($dir, "probe$Config{exe_ext}");

    open my $fh, '>', $c or return 0;
    print {$fh} "extern void $func();\nint main(void) { $func(); return 0; }\n";
    close $fh or return 0;

    my $null = File::Spec->devnull;
    my $cmd  = qq{$Config{cc} $Config{ldflags} -o "$exe" "$c" -ljq } .
               qq{> $null 2>&1};

    return system($cmd) == 0 ? 1 : 0;
}

# Does the linker take this flag?  Compiles and links a do-nothing shared
# object, which is cheap and a good deal more reliable than guessing from $^O.
sub ld_accepts {
    my ($flag) = @_;

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $c   = File::Spec->catfile($dir, 'probe.c');
    my $so  = File::Spec->catfile($dir, "probe.$Config{so}");

    open my $fh, '>', $c or return 0;
    print {$fh} "int jq_xs_probe(void) { return 0; }\n";
    close $fh or return 0;

    my $null = File::Spec->devnull;
    my $cmd  = qq{$Config{cc} $Config{cccdlflags} -shared $flag } .
               qq{-o "$so" "$c" > $null 2>&1};

    return system($cmd) == 0 ? 1 : 0;
}

WriteMakefile(
    NAME              => 'JQ::XS',
    VERSION_FROM      => 'lib/JQ/XS.pm',
    MIN_PERL_VERSION  => '5.026003',
    PREREQ_PM         => { 'JSON::PP' => 0 },
    TEST_REQUIRES     => {
        'Test::More'   => 0,
        'JSON::PP'     => 0,
        'Data::Dumper' => 0,
        'File::Temp'   => 0,
        'File::Spec'   => 0,
    },
    ABSTRACT_FROM     => 'lib/JQ/XS.pm',
    AUTHOR            => 'James Rouzier <rouzier@gmail.com>',
    LICENSE           => 'mit',
    %jq,
    # The vendored jq is unpacked and built by "make", not by "make clean &&
    # make", so it is left alone by clean and removed by realclean.  Rebuilding
    # it on demand is what "make jq_clean" is for.
    realclean         => { FILES => $JQ_BUILD },
    META_MERGE        => {
        'meta-spec' => { version => 2 },
        # Makefile.PL's output depends on JQ_SYSTEM, so it is not static.
        dynamic_config => 1,
        resources      => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rouzier/JQ-XS.git',
                web  => 'https://github.com/rouzier/JQ-XS',
            },
        },
    },
);

sub MY::postamble {
    my $frag = '';

    $frag .= <<"MAKE_FRAG" unless $system_jq;

JQ_TARBALL = $JQ_TARBALL
JQ_BUILD   = $JQ_BUILD
JQ_STAGE   = $JQ_STAGE
JQ_LIB     = \$(JQ_STAGE)/lib/libjq\$(LIB_EXT)
JQ_ONIG    = \$(JQ_STAGE)/lib/libonig\$(LIB_EXT)

# Unpack and build the vendored jq into \$(JQ_STAGE), statically and with PIC,
# so that libjq and its oniguruma end up inside XS.so and the installed module
# has no libjq to load at runtime.
#
# The compiler flags are assembled rather than hardcoded so the vendored jq is
# built the same way as the XS itself: \$(CCCDLFLAGS) is what makes the objects
# linkable into a shared object, and \$(OPTIMIZE) carries the packaging flags in
# both packaging paths -- rpm passes OPTIMIZE="\$RPM_OPT_FLAGS", and debhelper's
# perl_makemaker passes dpkg-buildflags' CFLAGS and CPPFLAGS the same way, which
# is what extends debian/rules' hardening=+all over jq too.  -O2 only leads as a
# floor, because a plain "perl Makefile.PL" leaves \$(OPTIMIZE) at perl's own
# "-g"; anything \$(OPTIMIZE) sets afterwards wins.
#
# jq's own build recurses into vendor/oniguruma, so the parent make's flags and
# jobserver are cleared first, as for the deb and rpm targets below.
\$(JQ_LIB) : \$(JQ_TARBALL) vendor/build-jq.pl
	env -u MAKEFLAGS -u MAKELEVEL -u MFLAGS \\
	    \$(FULLPERLRUN) vendor/build-jq.pl \\
		--tarball \$(JQ_TARBALL) \\
		--builddir \$(JQ_BUILD) \\
		--prefix \$(JQ_STAGE) \\
		--cc '\$(CC)' \\
		--cflags '-O2 \$(OPTIMIZE) \$(CCCDLFLAGS)' \\
		--make '\$(MAKE)'

# Produced by the rule above, in the same run.  Given its own rule rather than
# being a second target of that one, so that "make -j" cannot start the build
# twice.
\$(JQ_ONIG) : \$(JQ_LIB)
	\$(NOECHO) \$(NOOP)

# Throw the vendored jq away, so the next "make" builds it again.  Not part of
# "clean", which does not invalidate it.
jq_clean :
	\$(RM_RF) \$(JQ_BUILD)

.PHONY : jq_clean

MAKE_FRAG

    $frag .= <<'MAKE_FRAG';

DPKG_BUILDPACKAGE       = dpkg-buildpackage
DPKG_BUILDPACKAGE_FLAGS = -us -uc -b
# dpkg-buildpackage always drops its artifacts in the parent directory.
DEB_OUTDIR              = ..

# Build a Debian binary package from this source tree.  dpkg-buildpackage
# re-invokes this Makefile (debian/rules clean runs realclean, then the build
# step re-runs Makefile.PL), so the parent make's flags and jobserver are
# cleared first to keep the nested make independent.
#
# Override the tool or its flags to change what gets built, e.g.
#   make deb DPKG_BUILDPACKAGE_FLAGS="-us -uc"   # binary + source
#   make deb DPKG_BUILDPACKAGE=debuild
deb :
	@test -d debian || { \
	    echo "no debian/ directory here; run make deb from the source root" >&2; \
	    exit 1; \
	}
	env -u MAKEFLAGS -u MAKELEVEL -u MFLAGS \
	    $(DPKG_BUILDPACKAGE) $(DPKG_BUILDPACKAGE_FLAGS)
	@echo
	@echo "Packages built in $(DEB_OUTDIR):"
	@ls -1 $(DEB_OUTDIR)/*.deb 2>/dev/null || echo "  (none found)"

# Undo what "deb" leaves behind in the source tree.
deb_clean :
	@test ! -d debian || env -u MAKEFLAGS -u MAKELEVEL -u MFLAGS \
	    $(DPKG_BUILDPACKAGE) -T clean

.PHONY : deb deb_clean

RPMBUILD       = rpmbuild
RPMBUILD_FLAGS = -bb
RPM_SPEC       = rpm/perl-$(DISTNAME).spec
# Keep rpmbuild's scratch trees in the source tree rather than in ~/rpmbuild.
RPM_TOPDIR     = $(CURDIR)/rpmbuild

# Build an RPM from the release tarball "make dist" produces.  The spec's
# Source0 is JQ-XS-$(VERSION).tar.gz, so _sourcedir points here and the
# tarball is built in place, which saves copying it into a SOURCES directory.
# Any existing tarball is removed first: the dist rule compresses with plain
# gzip, which refuses to overwrite, and the RPM should be built from the
# current source anyway.  rpmbuild re-invokes this Makefile (%build runs
# Makefile.PL and make, %check runs make test), so the parent make's flags and
# jobserver are cleared first to keep that nested make independent.
#
# Override the tool or its flags to change what gets built, e.g.
#   make rpm RPMBUILD_FLAGS=-ba                  # binary + source RPM
#   make rpm RPMBUILD_FLAGS="-bb --nocheck"      # skip the test suite
rpm :
	@test -f $(RPM_SPEC) || { \
	    echo "no $(RPM_SPEC) here; run make rpm from the source root" >&2; \
	    exit 1; \
	}
	@spec_version=`sed -n 's/^Version:[[:space:]]*//p' $(RPM_SPEC)`; \
	test "$$spec_version" = "$(VERSION)" || { \
	    echo "$(RPM_SPEC) declares version $$spec_version, but this is $(VERSION);" >&2; \
	    echo "update Version: and %changelog in the spec first" >&2; \
	    exit 1; \
	}
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	$(MAKE) $(DISTVNAME).tar$(SUFFIX)
	$(MKPATH) $(RPM_TOPDIR)
	env -u MAKEFLAGS -u MAKELEVEL -u MFLAGS \
	    $(RPMBUILD) $(RPMBUILD_FLAGS) \
		--define '_topdir $(RPM_TOPDIR)' \
		--define '_sourcedir $(CURDIR)' \
		$(RPM_SPEC)
	@echo
	@echo "Packages built in $(RPM_TOPDIR):"
	@find $(RPM_TOPDIR)/RPMS $(RPM_TOPDIR)/SRPMS -name '*.rpm' 2>/dev/null | sort | grep . || echo "  (none found)"

# Undo what "rpm" leaves behind in the source tree.
rpm_clean :
	$(RM_RF) $(RPM_TOPDIR)

.PHONY : rpm rpm_clean

MAKE_FRAG

    return $frag;
}
