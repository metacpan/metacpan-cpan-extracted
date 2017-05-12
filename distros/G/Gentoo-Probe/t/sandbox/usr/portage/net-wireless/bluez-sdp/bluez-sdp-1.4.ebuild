# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/bluez-sdp/bluez-sdp-1.4.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="bluetooth service discovery protocol (sdp) utilities"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86"
IUSE=""
DEPEND=">=net-wireless/bluez-libs-2.4"

src_compile() {
	econf || die "econf failed"
	emake || die
}

src_install() {
	make DESTDIR=${D} install || die
}
