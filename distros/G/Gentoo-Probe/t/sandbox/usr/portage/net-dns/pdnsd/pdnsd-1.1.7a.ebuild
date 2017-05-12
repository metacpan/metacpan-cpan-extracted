# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/pdnsd/pdnsd-1.1.7a.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

S=${WORKDIR}/${P}
DESCRIPTION="Proxy DNS server with permanent caching"
SRC_URI="http://home.t-online.de/home/Moestl/${P}.tar.bz2"
HOMEPAGE="http://home.t-online.de/home/Moestl/"

DEPEND="virtual/glibc"

SLOT="0"
LICENSE="BSD | GPL-2"
KEYWORDS="x86 ppc sparc "

src_compile() {
	econf \
		--sysconfdir=/etc/pdnsd \
		--with-cachedir=/var/lib/pdnsd \
		|| die "bad configure"

	emake all || die "compile problem"
}

src_install() {
	make DESTDIR=${D} install || die

	dodoc AUTHORS COPYING* ChangeLog* NEWS README THANKS TODO
	docinto contrib ; dodoc contrib/{README,dhcp2pdnsd,pdnsd_dhcp.pl}
	docinto html ; dohtml doc/html/*
	docinto txt ; dodoc doc/txt/*
	newdoc doc/pdnsd.conf pdnsd.conf.sample

	exeinto /etc/init.d ; newexe ${FILESDIR}/pdnsd.rc6 pdnsd
}

