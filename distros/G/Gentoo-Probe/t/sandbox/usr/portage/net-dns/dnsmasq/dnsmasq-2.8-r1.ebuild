# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/dnsmasq/dnsmasq-2.8-r1.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

MY_P="${P/_/}"
MY_PV="${PV/_rc*/}"
DESCRIPTION="Small forwarding DNS server for local networks"
HOMEPAGE="http://www.thekelleys.org.uk/dnsmasq/"
SRC_URI="http://www.thekelleys.org.uk/dnsmasq/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~ppc sparc ~mips arm amd64 ~ia64 s390"
IUSE=""

DEPEND="virtual/glibc
	>=sys-apps/sed-4"

S="${WORKDIR}/${PN}-${MY_PV}"

src_unpack() {
	unpack ${A}
	cd ${S}
	sed -i "s:-O2:\"${CFLAGS}\":" Makefile
	sed -i "s:-O2:\"${CFLAGS}\":" src/Makefile
}

src_compile() {
	emake || die
}

src_install() {
	dosbin src/dnsmasq || die
	doman dnsmasq.8
	dodoc CHANGELOG FAQ
	dohtml *.html

	exeinto /etc/init.d
	newexe ${FILESDIR}/dnsmasq-init dnsmasq
	insinto /etc/conf.d
	newins ${FILESDIR}/dnsmasq.confd dnsmasq
	insinto /etc
	newins dnsmasq.conf.example dnsmasq.conf
}
