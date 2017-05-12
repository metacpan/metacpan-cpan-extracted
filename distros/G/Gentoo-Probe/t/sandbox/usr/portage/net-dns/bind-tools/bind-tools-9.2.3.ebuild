# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/bind-tools/bind-tools-9.2.3.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit flag-o-matic

MY_P=${P//-tools}
MY_P=${MY_P/_}
S=${WORKDIR}/${MY_P}
DESCRIPTION="bind tools: dig, nslookup, and host"
SRC_URI="ftp://ftp.isc.org/isc/bind9/${PV/_}/${MY_P}.tar.gz"
HOMEPAGE="http://www.isc.org/products/BIND/bind9-beta.html"

KEYWORDS="-x86 -ppc -sparc -alpha -hppa -amd64 -ia64"
LICENSE="as-is"
SLOT="0"

DEPEND="virtual/glibc"

src_compile() {

	# Set -fPIC compiler option to enable compilation on 64-bit archs
	# (Bug #33336)
	if use alpha || use amd64 || use ia64; then
		append-flags -fPIC
	fi

	use ipv6 && myconf="${myconf} --enable-ipv6" || myconf="${myconf} --enable-ipv6=no"

	econf ${myconf} || die "Configure failed"

	export MAKEOPTS="${MAKEOPTS} -j1"

	cd ${S}/lib/isc
	make && ld -shared -s -o libisc.so -whole-archive libisc.a \
	|| die "make failed in /lib/isc"
	cp libisc.so ../../bin/dig/ || die "Failed to build libisc"

	cd ${S}/lib/dns
	make && ld -shared -s -o libdns.so -whole-archive libdns.a \
	|| die "make failed in /lib/dns"
	cp libdns.so ../../bin/dig/ || die "Failed to build libdns"

	cd ${S}/bin/dig
	cp Makefile Makefile.org
	sed -e 's:../../lib/dns/libdns.a:libdns.so:' \
	-e 's:../../lib/isc/libisc.a:libisc.so:' \
	Makefile.org > Makefile || die
	make || die "Failed to build dig"
}

src_install() {
	cd ${S}/lib/dns
	dolib libdns.so

	cd ${S}/lib/isc
	dolib libisc.so

	cd ${S}/bin/dig
	dobin dig host nslookup
	doman dig.1 host.1

	doman ${FILESDIR}/nslookup.8

	cd ${S}
	dodoc  README CHANGES FAQ COPYRIGHT
}
