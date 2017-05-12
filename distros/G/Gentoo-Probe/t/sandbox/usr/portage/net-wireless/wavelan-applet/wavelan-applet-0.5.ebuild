# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# Authour: Mikael Hallendal <hallski@gentoo.org>
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/wavelan-applet/wavelan-applet-0.5.ebuild,v 1.1 2004/06/20 09:09:37 linguist Exp $

S=${WORKDIR}/${P}
DESCRIPTION="GNOME Panel applet that shows the strength of a wavelan connection"
SRC_URI="http://www.eskil.org/${PN}/${P}.tar.gz"
HOMEPAGE="http://www.eskil.org/wavelan-applet/"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 sparc "

RDEPEND=">=gnome-base/gnome-core-1.2.12
	 <gnome-base/eel-2
	 <gnome-base/libglade-1.99"

DEPEND="${RDEPEND}
	sys-devel/gettext"

src_unpack() {
	unpack ${A}

	cd ${S}
	patch -p1 < ${FILESDIR}/wavelan-0.5-nosegfault.patch
}


src_compile() {
	./configure --host=${CHOST} \
		    --prefix=/usr \
		    --sysconfdir=/etc \
		    --localstatedir=/var/lib
	assert "Package configuration failed."

	emake || die "Package building failed."
}

src_install() {
	make prefix=${D}/usr \
	     sysconfdir=${D}/etc \
	     localstatedir=${D}/var/lib \
	     install || die

	dodoc AUTHORS COPYING* ChangeLog README NEWS
}
