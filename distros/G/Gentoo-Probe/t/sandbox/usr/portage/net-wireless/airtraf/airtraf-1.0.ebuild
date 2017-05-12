# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/airtraf/airtraf-1.0.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="AirTraf 802.11b Wireless traffic sniffer"
HOMEPAGE="http://www.elixar.com/"
SRC_URI="http://www.elixar.com/${P}.tar.gz"

IUSE=""

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="x86"

DEPEND=">=net-libs/libpcap-0.7.1"

src_compile() {
	cd ${S}/src

	# Do some sedding to make compile flags work

	mv Makefile.rules ${T}
	sed -e "s:gcc:${CC}:" \
		-e "s:CFLAGS   = -Wall -O2:CFLAGS   = ${CFLAGS} -Wall:" \
		-e "s:c++:${GXX}:" \
		-e "s:CXXFLAGS = -Wall -O2:CXXFLAGS = ${GXXFLAGS} -Wall:" \
		${T}/Makefile.rules > Makefile.rules
	make || die
}

src_install () {
	newdoc ${S}/docs/airtraf_doc.html airtraf_documentation.html

	dobin ${S}/src/airtraf || die
}
