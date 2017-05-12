# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/ddclient/ddclient-3.6.3.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit eutils

S=${WORKDIR}/${P}
DESCRIPTION="A perl based client for dyndns"
HOMEPAGE="http://burry.ca:4141/ddclient/"
SRC_URI="http://members.rogers.com/ddclient/pub/${P}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~ppc ~sparc alpha ~hppa ~mips ~amd64 ~ia64"

RDEPEND="dev-lang/perl"

src_unpack() {
	unpack ${A}
	cd ${S}
	epatch ${FILESDIR}/${PF}-gentoo.diff
	epatch ${FILESDIR}/${PF}-mss1.diff
}

src_install () {
	exeinto /usr/sbin
	doexe ddclient
	insinto /etc/ddclient
	doins sample-*
	dodoc README COPYING COPYRIGHT
	exeinto /etc/init.d
	newexe ${FILESDIR}/ddclient.rc6 ddclient
}
