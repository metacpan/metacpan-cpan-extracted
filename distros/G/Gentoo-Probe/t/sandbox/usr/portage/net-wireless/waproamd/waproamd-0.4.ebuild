# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/waproamd/waproamd-0.4.ebuild,v 1.1 2004/06/20 09:09:37 linguist Exp $

DESCRIPTION="Wireless roaming daemon for configuring wireless settings"

HOMEPAGE="http://www.stud.uni-hamburg.de/~lennart/projects/waproamd/"
SRC_URI="http://0pointer.de/lennart/projects/waproamd/${P}.tar.gz"
LICENSE="GPL-2"

SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="dev-libs/libdaemon"

src_unpack() {
	unpack ${A}

	cd ${S}
	cp ${FILESDIR}/waproamd.initd ${S}/conf/waproamd.init.in
}

src_compile() {
	econf --disable-lynx || die
	emake || die
}

src_install() {
	einstall || die
	dodoc README
	insinto /etc/conf.d
	newins ${FILESDIR}/waproamd.confd waproamd
}
