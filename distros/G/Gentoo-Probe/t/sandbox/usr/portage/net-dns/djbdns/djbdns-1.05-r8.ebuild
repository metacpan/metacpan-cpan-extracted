# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/djbdns/djbdns-1.05-r8.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

IUSE="ipv6 static"

inherit eutils

PATCHVER=0.2
DESCRIPTION="Excellent high-performance DNS services"
HOMEPAGE="http://cr.yp.to/djbdns.html"
SRC_URI="http://cr.yp.to/djbdns/${P}.tar.gz
	http://www.skarnet.org/software/djbdns-fwdzone/djbdns-1.04-fwdzone.patch
	http://www.legend.co.uk/djb/dns/round-robin.patch
	ipv6? ( mirror://gentoo/${P}-ipv6-gentoo-${PATCHVER}.diff.bz2 )"

SLOT="0"
LICENSE="as-is"
KEYWORDS="x86 sparc ~ppc alpha ~mips ~hppa"

RDEPEND=">=sys-apps/daemontools-0.70
	sys-apps/ucspi-tcp"

src_unpack() {
	unpack ${A}
	cd ${S}

	epatch ${DISTDIR}/djbdns-1.04-fwdzone.patch
	epatch ${DISTDIR}/round-robin.patch
	epatch ${FILESDIR}/${PV}-errno.patch
	epatch ${FILESDIR}/headtail.patch
	use ipv6 && epatch ${WORKDIR}/djbdns-1.05-ipv6-gentoo-${PATCHVER}.diff
}

src_compile() {
	LDFLAGS=
	use static && LDFLAGS="-static"
	echo "gcc ${CFLAGS}" > conf-cc
	echo "gcc ${LDFLAGS}" > conf-ld
	echo "/usr" > conf-home
	MAKEOPTS="-j1" emake || die "emake failed"
}

src_install() {
	insinto /etc
	doins dnsroots.global
	into /usr
	dobin *-conf dnscache tinydns walldns rbldns pickdns axfrdns \
	      *-get *-data *-edit dnsip dnsipq dnsname dnstxt dnsmx \
	      dnsfilter random-ip dnsqr dnsq dnstrace dnstracesort
	#Fix #20690.
	use ipv6 && dobin dnsip6 dnsip6q

	dodoc CHANGES FILES README SYSDEPS TARGETS TODO VERSION

	dobin ${FILESDIR}/dnscache-setup
	dobin ${FILESDIR}/tinydns-setup
}

pkg_postinst() {
	groupadd &>/dev/null nofiles
	id &>/dev/null dnscache || \
		useradd -g nofiles -d /nonexistent -s /bin/false dnscache
	id &>/dev/null dnslog || \
		useradd -g nofiles -d /nonexistent -s /bin/false dnslog
	id &>/dev/null tinydns || \
		useradd -g nofiles -d /nonexistent -s /bin/false tinydns

	einfo "Use dnscache-setup and tinydns-setup to help you"
	einfo "configure your nameservers!"
}
