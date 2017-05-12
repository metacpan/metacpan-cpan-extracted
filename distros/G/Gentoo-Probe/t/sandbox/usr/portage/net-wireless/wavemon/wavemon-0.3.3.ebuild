# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/wavemon/wavemon-0.3.3.ebuild,v 1.1 2004/06/20 09:09:37 linguist Exp $

S=${WORKDIR}/${P}
DESCRIPTION="ncurses based monitor util for your wavelan cards"
SRC_URI="http://www.jm-music.de/wavemon-current.tar.gz"
HOMEPAGE="http://www.janmorgenstern.de/projects-software.html"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="x86 ppc sparc "

DEPEND="sys-libs/ncurses"

src_compile() {
	emake || die
}

src_install() {
	dodir /usr/bin
	dodir /usr/share/man/{man1,man5}
	make prefix="${D}/usr" mandir="${D}/usr/share/man" install
	dodoc README TODO COPYING AUTHORS
}
