# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/djbdns/djbdns-1.05-r11.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

IUSE="ipv6 ipv6arpa static fwdzone roundrobin multipleip"

inherit eutils

DESCRIPTION="Excellent high-performance DNS services"
HOMEPAGE="http://cr.yp.to/djbdns.html"
SRC_URI="http://cr.yp.to/djbdns/${P}.tar.gz
	fwdzone? ( http://www.skarnet.org/software/djbdns-fwdzone/djbdns-1.04-fwdzone.patch )
	roundrobin? ( http://www.legend.co.uk/djb/dns/round-robin.patch )
	multipleip? ( http://danp.net/djbdns/dnscache-multiple-ip.patch
	              http://www.ohse.de/uwe/patches/djbdns-1.05-multiip.diff )
	ipv6? ( http://www.fefe.de/dns/djbdns-1.05-test20.diff.bz2 )"

SLOT="0"
LICENSE="as-is"
KEYWORDS="~x86"

RDEPEND=">=sys-apps/daemontools-0.70
	sys-apps/ucspi-tcp"

src_unpack() {
	unpack ${A}
	cd ${S}

	use ipv6 && use multipleip && \
	eerror "ipv6 cannot currently be used with the multipleip patch" && \
	exit -1

	use ipv6 && ( use fwdzone || use roundrobin ) && \
	eerror "ipv6 cannot currently be used with the fwdzone or " && \
	eerror "roundrobin patch." && \
	eerror && \
	eerror "If you would like to see ipv6 support along with one of " && \
	eerror "those other patches please submit a working patch that " && \
	eerror "combines ipv6 with either fwdzone or roundrobin but not " && \
	eerror "both at the same time, since the latter 2 patches are " && \
	eerror "mutually exclusive according to bug #31238." && exit -1

	use fwdzone && use roundrobin && \
	eerror "fwdzone and roundrobin do not work together according " && \
	eerror "to bug #31238" && exit -1

	use fwdzone && epatch ${DISTDIR}/djbdns-1.04-fwdzone.patch
	use roundrobin && epatch ${DISTDIR}/round-robin.patch
	use ipv6 && epatch ${WORKDIR}/djbdns-1.05-test20.diff
	use ipv6 && use ipv6arpa && \
		epatch ${FILESDIR}/djbdns-1.05-ipv6arpa+BSDok-gentoo.diff
	use multipleip && \
		epatch ${DISTDIR}/dnscache-multiple-ip.patch && \
		epatch ${DISTDIR}/djbdns-1.05-multiip.diff

	epatch ${FILESDIR}/${PV}-errno.patch
	epatch ${FILESDIR}/headtail.patch
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
