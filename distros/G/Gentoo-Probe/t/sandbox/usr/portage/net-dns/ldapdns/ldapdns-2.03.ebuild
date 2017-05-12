# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/ldapdns/ldapdns-2.03.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

S=${WORKDIR}/${P}
DESCRIPTION="A tiny, fast authoritative nameserver that queries LDAP and can be updated instantly"
SRC_URI="http://www.nimh.org/dl/${P}.tar.gz"
HOMEPAGE="http://www.nimh.org/code/ldapdns/"
IUSE=""

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="x86"

DEPEND="virtual/glibc
	>=net-nds/openldap-2"
RDEPEND="${DEPEND}
	>=sys-apps/daemontools-0.70
	sys-apps/ucspi-tcp"

src_compile() {
	local myconf="--prefix=/usr "

	cd ${S}
	./configure ${myconf}
	emake || die "Compilation failed"
}

src_install() {
	einstall || die "Installation failed"


	dodoc AUTHORS CHANGELOG FAQ INSTALL  COPYING NEWS README* TODO
}

pkg_postinst() {

	groupadd &>/dev/null nofiles

	id &>/dev/null ldapdns || \
		useradd -g nofiles -d /nonexistent -s /bin/false ldapdns
	id &>/dev/null dnslog || \
		useradd -g nofiles -d /nonexistent -s /bin/false dnslog

	einfo "Read the readme.configure and use ldapdns-conf to setup"
}

