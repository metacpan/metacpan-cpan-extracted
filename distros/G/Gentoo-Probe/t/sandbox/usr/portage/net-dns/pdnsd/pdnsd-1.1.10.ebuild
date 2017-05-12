# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/pdnsd/pdnsd-1.1.10.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit eutils

DESCRIPTION="Proxy DNS server with permanent caching"

MY_P=${PN}-${PV}-par

SRC_URI="http://www.phys.uu.nl/%7Erombouts/pdnsd/${MY_P}.tar.gz"

HOMEPAGE="http://www.phys.uu.nl/%7Erombouts/pdnsd.html http://home.t-online.de/home/Moestl"

IUSE="ipv6 debug isdn"

DEPEND="virtual/glibc
	sys-apps/sed
	sys-apps/gawk
	sys-devel/libtool
	sys-devel/gcc
	sys-devel/automake
	sys-devel/autoconf"

RDEPEND="virtual/glibc"

SLOT="0"
LICENSE="BSD | GPL-2"

# Should work on  alpha arm hppa i386 ia64 m68k mips mipsel powerpc s390 sparc 
# REF http://packages.debian.org/cgi-bin/search_packages.pl?searchon=names&version=all&exact=1&keywords=pdnsd

KEYWORDS="x86 ppc sparc alpha ~s390 ~amd64"

S=${WORKDIR}/${PN}-${PV}


# for debugging use
use debug && RESTRICT="${RESTRICT} nostrip"

src_compile() {
	cd ${S} || die
	local myconf

	if use debug; then
	 	myconf="${myconf} --with-debug=3"
		CFLAGS="${CFLAGS} -g"
	fi
	[ -c /dev/urandom ] && myconf="${myconf} --with-random-device=/dev/urandom"

	econf \
		--sysconfdir=/etc/pdnsd \
		--with-cachedir=/var/cache/pdnsd \
		--infodir=/usr/share/info --mandir=/usr/share/man \
		--with-default-id=pdnsd \
		`use_enable ipv6` `use_enable isdn` \
		${myconf} \
		|| die "bad configure"

	emake all || die "compile problem"
}

pkg_preinst() {
	enewgroup pdnsd
	enewuser pdnsd -1 /bin/false /var/lib/pdnsd pdnsd
}

src_install() {

	emake DESTDIR=${D} install || die

	# Copy cache from prev versions
	[ -f ${ROOT}/var/lib/pdnsd/pdnsd.cache ] && \
		cp ${ROOT}/var/lib/pdnsd/pdnsd.cache ${D}/var/cache/pdnsd/pdnsd.cache

	# Don't clobber existing cache - copy prev cache so unmerging prev version
	# doesn't remove the cache.
	[ -f ${ROOT}/var/cache/pdnsd/pdnsd.cache ] && \
		cp ${ROOT}/var/cache/pdnsd/pdnsd.cache ${D}/var/cache/pdnsd/pdnsd.cache

	dodoc AUTHORS COPYING* ChangeLog* NEWS README THANKS TODO README.par
	docinto contrib ; dodoc contrib/{README,dhcp2pdnsd,pdnsd_dhcp.pl}
	docinto html ; dohtml doc/html/*
	docinto txt ; dodoc doc/txt/*
	newdoc doc/pdnsd.conf pdnsd.conf.sample

	# Remind users that the cachedir has moved to /var/cache
	#[ -f ${ROOT}/etc/pdnsd/pdnsd.conf ] && \
	#	sed -e "s#/var/lib#/var/cache#g" ${ROOT}/etc/pdnsd/pdnsd.conf \
	#	> ${D}/etc/pdnsd/pdnsd.conf

	exeinto /etc/init.d
	newexe ${FILESDIR}/pdnsd.rc6 pdnsd
	newexe ${FILESDIR}/pdnsd.online pdnsd-online

	use ipv6 && \
		ewarn "make sure your servers in /etc/pdnsd/pdnsd.conf are reachable with IPv6"

	keepdir /etc/conf.d
	local config=${D}/etc/conf.d/pdnsd-online

	${D}/usr/sbin/pdnsd --help | sed "s/^/# /g" > ${config}
	echo -e "\n\n# Enter the interface that connects you to the dns servers" >> ${config}
	echo "# This will correspond to /etc/init.d/net.${IFACE}" >> ${config}
	echo -e "\n# IMPORTANT: Be sure to run depscan.sh after modifiying IFACE" >>  ${config}
	echo "IFACE=ppp0" >> ${config}
	echo "# Command line options" >> ${config}
	use ipv6 && echo PDNSDCONFIG="-6" >> ${config} \
		|| echo PDNSDCONFIG="" >> ${config}

}

pkg_postinst() {
	einfo
	einfo "Add pdnsd to your default runlevel - rc-update add pdnsd default"
	einfo ""
	einfo "Add pdnsd-online to your online runlevel."
	einfo "The online interface will be listed in /etc/conf.d/pdnsd-online"
	einfo ""
	einfo "Sample config file in /etc/pdnsd/pdnsd.conf.sample"

}
