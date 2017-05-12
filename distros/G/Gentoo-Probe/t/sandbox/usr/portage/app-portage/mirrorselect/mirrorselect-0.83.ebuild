# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/mirrorselect/mirrorselect-0.83.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="Tool to help select distfiles mirrors for Gentoo"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${PF}.tbz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc mips alpha arm hppa amd64 ppc64 s390"
IUSE=""

RDEPEND=">=dev-util/dialog-0.7
	sys-apps/grep
	sys-apps/sed
	sys-apps/gawk
	net-misc/wget
	net-analyzer/netselect"

S=${WORKDIR}

src_install() {
	dosbin ${S}/mirrorselect || die
}
