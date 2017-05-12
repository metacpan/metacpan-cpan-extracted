# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/airsnort/airsnort-0.2.1a.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

MY_P=${P/a/A}
S=${WORKDIR}/${MY_P}
DESCRIPTION="802.11b Wireless Packet Sniffer/WEP Cracker"
HOMEPAGE="http://airsnort.shmoo.com/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="x86 ppc -sparc"

DEPEND=">=sys-devel/autoconf-2.13
	=x11-libs/gtk+-1*
	>=net-libs/libpcap-0.7.1
	pcmcia? ( >=sys-apps/pcmcia-cs-3.1.33 )"

src_compile() {
	./autogen.sh \
		--host=${CHOST} \
		--prefix=/usr \
		--infodir=/usr/share/info \
		--mandir=/usr/share/man || die "./autogen failed"
	make || die
}

src_install() {
	make DESTDIR=${D} install || die
	dodoc README README.crypt Authors ChangeLog TODO
}
pkg_postinst() {
	einfo "Make sure to emerge linux-wlan-ng if you want support"
	einfo "for Prism2 based cards in airsnort."
}

