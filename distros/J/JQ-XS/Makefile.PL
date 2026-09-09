use 5.026003;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'JQ::XS',
    VERSION_FROM      => 'lib/JQ/XS.pm',
    PREREQ_PM         => { 'JSON::PP' => 0 },
    ABSTRACT_FROM     => 'lib/JQ/XS.pm',
    AUTHOR            => 'James Rouzier <rouzier@gmail.com>',
    LICENSE           => 'mit',
    LIBS              => ['-ljq'],
    DEFINE            => '',
    INC               => '-I.',
);

# The "deb" target below drives debian/ packaging from the generated Makefile.
sub MY::postamble {
    return <<'MAKE_FRAG';

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
}
