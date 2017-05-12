# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/ksh/ksh-93.20030724.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit ccc eutils flag-o-matic

RELEASE="2003-07-24"
DESCRIPTION="The Original Korn Shell, 1993 revision (ksh93)"
HOMEPAGE="http://www.kornshell.com/"
SRC_URI="http://www.research.att.com/~gsf/download/tgz/INIT.${RELEASE}.tgz
	http://www.research.att.com/~gsf/download/tgz/ast-ksh.${RELEASE}.tgz
	nls? ( http://www.research.att.com/~gsf/download/tgz/ast-ksh-locale.2003-04-22.tgz )"

LICENSE="ATT"
SLOT="0"
KEYWORDS="x86 alpha sparc"
IUSE="static nls"

DEPEND="virtual/glibc !app-shells/pdksh"

S=${WORKDIR}

src_unpack() {
	# the AT&T build tools look in here for packages.
	mkdir -p ${S}/lib/package/tgz

	# move the packages into place.
	cp ${DISTDIR}/ast-ksh.${RELEASE}.tgz ${S}/lib/package/tgz/ || die

	if use nls; then
		cp ${DISTDIR}/ast-ksh-locale.2003-04-22.tgz ${S}/lib/package/tgz/ || die
	fi

	# INIT provides the basic tools to start building.
	unpack INIT.${RELEASE}.tgz

	# `package read` will unpack any tarballs put in place.
	${S}/bin/package read || die

	# fix some craziness.
	epatch ${FILESDIR}/ksh-93.20030724-libs.diff
}

src_compile() {
	# users who prefer ksh as there regular shell
	# may want to make it static, so it can be used
	# in the event of fs failure, for example
	# where shared libraries are not available
	use static && append-ldflags -static

	# set the optimisations for the build process
	export CCFLAGS="${CFLAGS}"
	cd ${S}; ./bin/package only make ast-ksh CC=${CC:-gcc} || die

	# install the optional locale data.
	# heh, check out locale fudd, or piglatin :)
	#
	# "Too many symbowic winks in paf name twavewsal"

	# david korn is a funny guy! :)
	if use nls; then
		cd ${S}; ./bin/package only make ast-ksh-locale CC=${CC:-gcc}
	fi
}

src_install() {
	# check where the build scripts put them
	local my_arch="${S}/arch/$(${S}/bin/package)"

	exeinto /bin
	doexe ${my_arch}/bin/ok/ksh

	# FIXME: talk to pdksh maintainer about making this nicer,
	# 		how can we co-exist nicely without blocking?
	dosym /bin/ksh /bin/ksh93

	newman ${my_arch}/man/man1/sh.1 ksh.1
	dodoc lib/package/LICENSES/ast lib/package/gen/ast-ksh.txt

	if use nls; then
		dodir /usr/share
		mv ${S}/share/lib/locale ${D}/usr/share
	fi
}
