# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/bluez-pan/bluez-pan-1.1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="Bluetooth PAN profile implementation"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~sparc ~ppc"
IUSE=""
DEPEND=">=net-wireless/bluez-libs-2.2
	>=net-wireless/bluez-sdp-1.0"

src_install() {
	einstall || die
}
