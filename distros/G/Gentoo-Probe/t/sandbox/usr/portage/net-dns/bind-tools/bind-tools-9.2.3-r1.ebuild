# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/bind-tools/bind-tools-9.2.3-r1.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit flag-o-matic gnuconfig

MY_P=${P//-tools}
MY_P=${MY_P/_}
S=${WORKDIR}/${MY_P}
DESCRIPTION="bind tools: dig, nslookup, and host"
HOMEPAGE="http://www.isc.org/products/BIND/bind9-beta.html"
SRC_URI="ftp://ftp.isc.org/isc/bind9/${PV/_}/${MY_P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="x86 ppc sparc alpha arm hppa ~amd64 ~ia64 s390 mips ppc64"
IUSE=""

DEPEND="virtual/glibc"

src_compile() {
	# Set -fPIC compiler option to enable compilation on 64-bit archs
	# (Bug #33336)
	if use alpha || use amd64 || use ia64; then
		append-flags -fPIC
	fi

	(use ppc64 || use mips) && gnuconfig_update

	use ipv6 && myconf="${myconf} --enable-ipv6" || myconf="${myconf} --enable-ipv6=no"

	econf ${myconf} || die "Configure failed"

	export MAKEOPTS="${MAKEOPTS} -j1"

	cd ${S}/lib/isc
	emake || die "make failed in /lib/isc"

	cd ${S}/lib/dns
	emake || die "make failed in /lib/dns"

	cd ${S}/bin/dig
	emake || die "make failed in /bin/dig"
}

src_install() {
	dodoc README CHANGES FAQ
	doman ${FILESDIR}/nslookup.8

	cd ${S}/bin/dig
	dobin dig host nslookup || die
	doman dig.1 host.1
}
