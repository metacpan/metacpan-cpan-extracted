# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/wireless-tools/wireless-tools-26.ebuild,v 1.1 2004/06/20 09:09:37 linguist Exp $

MY_P=wireless_tools.${PV/_/\.}
S=${WORKDIR}/${MY_P}
DESCRIPTION="A collection of tools to configure wireless lan cards."
SRC_URI="http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/${MY_P}.tar.gz"
HOMEPAGE="http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/Tools.html"
KEYWORDS="x86 ppc amd64"
SLOT="0"
LICENSE="GPL-2"
DEPEND="virtual/glibc"
RDEPEND="${DEPEND}"
IUSE=""

src_unpack() {
	unpack ${A}
	cd ${S}

	check_KV

	mv Makefile ${T}
	sed -e "s:# KERNEL_SRC:KERNEL_SRC:" \
		${T}/Makefile > Makefile
}

src_compile() {
	emake CFLAGS="$CFLAGS" WARN="" || die
}

src_install () {
	dosbin iwconfig iwevent iwgetid iwpriv iwlist iwspy
	dolib libiw.so.26 libiw.a
	doman iwconfig.8 iwlist.8 iwpriv.8 iwspy.8
	dodoc CHANGELOG.h COPYING INSTALL PCMCIA.txt README

	insinto /usr/include
	doins iwlib.h
	dosym /usr/lib/libiw.so.26 /usr/lib/libiw.so
}
