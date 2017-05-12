# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/porthole/porthole-0.3-r1.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit eutils

DESCRIPTION="A GTK+-based frontend to Portage"
HOMEPAGE="http://porthole.sourceforge.net"
SRC_URI="mirror://sourceforge/porthole/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~ppc"
IUSE=""
DEPEND=">=dev-lang/python-2.3
		>=gnome-base/libglade-2
		>=dev-python/pygtk-2.0.0
		dev-python/pyxml"

src_unpack() {
	unpack ${P}.tar.bz2
	epatch ${FILESDIR}/cvs-update-20040414.patch
}

src_install() {
	python setup.py install --root=${D} || die
	chmod -R a+r ${D}/usr/share/porthole
	chmod -R a+r ${D}/usr/doc/porthole-0.3
}
