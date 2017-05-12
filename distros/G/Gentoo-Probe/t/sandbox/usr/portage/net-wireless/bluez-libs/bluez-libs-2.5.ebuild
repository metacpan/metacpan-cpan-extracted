# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/bluez-libs/bluez-libs-2.5.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit gnuconfig

DESCRIPTION="Bluetooth Userspace Libraries"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~sparc ~ppc ~amd64"
IUSE=""
DEPEND=""

src_unpack() {
	unpack ${A}
	cd ${S}

	gnuconfig_update
}

src_compile() {
	use amd64 && sed -i -e 's/CFLAGS\ =\ @CFLAGS@/CFLAGS\ =\ @CFLAGS@\ -fPIC/' src/Makefile.in
	econf || die "econf failed"
	emake || die
}

src_install() {
	make DESTDIR=${D} install || die
}
