# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/mfedit/mfedit-0.60.2.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

DESCRIPTION="A graphical editor for DNS master files"
HOMEPAGE="http://www.posadis.org/projects/mfedit.php"
SRC_URI="mirror://sourceforge/posadis/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE=""

DEPEND=">=dev-cpp/poslib-1.0.2
	=x11-libs/gtk+-1.2*"

src_compile() {
	econf || die
	emake || die
}

src_install() {
	make DESTDIR=${D} install || die
	dodoc AUTHORS ChangeLog INSTALL NEWS README TODO
}
