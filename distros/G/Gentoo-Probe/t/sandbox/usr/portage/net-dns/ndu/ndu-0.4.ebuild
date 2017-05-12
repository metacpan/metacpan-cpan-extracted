# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/ndu/ndu-0.4.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="DNS serial number incrementer and reverse zone builder"
URI_BASE="http://uranus.it.swin.edu.au/~jn/linux/"
SRC_URI="${URI_BASE}/${P}.tar.gz"
HOMEPAGE="${URI_BASE}/dns.htm"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""
DEPEND="sys-apps/sed virtual/glibc"
RDEPEND="net-dns/bind virtual/glibc"
S=${WORKDIR}/${P}

src_compile() {
	cd ${S}/src
	sed -i 's|gcc|$(CXX)|g' Makefile
	sed -i 's|#define CONFIG_PATH "/etc/"|#define CONFIG_PATH "/etc/bind/"|g' ndc.c
	emake
	sed -i 's|VISUAL|EDITOR|g' dnsedit
	cd ${S}
	sed -i 's|0.0.127.in-addr.arpa|127.in-addr.arpa|g' ndu.conf
	echo '## if you use a chrooted setup, then you need to uncomment these lines:' >>ndu.conf
	echo '#process "/chroot/dns/named.conf"' >>ndu.conf
	echo '#chroot "/chroot/dns"' >>ndu.conf
}

src_install () {
	into /usr
	dosbin src/{dnsedit,ndu}
	dobin src/dnstouch
	into /
	insinto /etc/bind
	doins ndu.conf
	dodoc README INSTALL
}
