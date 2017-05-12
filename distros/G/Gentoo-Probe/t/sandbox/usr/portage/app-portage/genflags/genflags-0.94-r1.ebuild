# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/genflags/genflags-0.94-r1.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="Gentoo CFLAGS generator"

HOMEPAGE="http://www.gentoo.org/"

SRC_URI="mirror://gentoo/${P}-bin.tar.bz2
		 mirror://gentoo/${P}-devel.tar.bz2
		 http://dev.gentoo.org/~robbat2/genflags/${P}-bin.tar.bz2
		 http://dev.gentoo.org/~robbat2/genflags/${P}-devel.tar.bz2"

LICENSE="OSL-1.1"

SLOT="0"

KEYWORDS="x86 amd64 hppa ppc mips sparc alpha"
# should also work on : ia64 m68k cris s390 sh

IUSE=""

# This is all explictly specified as might want this in early stages
DEPEND="app-shells/bash
		|| ( sys-apps/coreutils ( sys-apps/sh-utils sys-apps/textutils ) )
		sys-apps/findutils
		sys-apps/grep
		sys-apps/sed
		sys-apps/util-linux"

S=${WORKDIR}/${P}

src_compile() {
	einfo "No compiling needed!"
}

src_install() {
	for i in bin/* ; do
		dosbin ${i}
	done
	for i in LICENSE README docs/* ; do
		dodoc ${i}
	done
	cp -r data ${D}/usr/share/genflags

	# At this time, don't install these dirs:
	# old rawdata extra scripts testoutput testscripts

}

pkg_postinst() {
	ewarn "This program does currently NOT detect all AMD chips correctly."
	ewarn "It CANNOT identify athlon-tbirds. It also gets confused between"
	ewarn "AMD-K6{,-2,-3} and Athlon vs. Athlon-4."
	einfo "Please file any patches/bugs to robbat2@gentoo.org via the Gentoo"
	einfo "Bugzilla."
	einfo "See /usr/share/doc/${PF}/README for quick instructions."
}
