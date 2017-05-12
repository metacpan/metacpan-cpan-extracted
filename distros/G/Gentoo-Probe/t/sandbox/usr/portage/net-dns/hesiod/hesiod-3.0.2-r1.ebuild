# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/hesiod/hesiod-3.0.2-r1.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit flag-o-matic eutils

DESCRIPTION="system which uses existing DNS functionality to provide access to databases of information that changes infrequently"
HOMEPAGE="ftp://athena-dist.mit.edu/pub/ATHENA/hesiod"
SRC_URI="ftp://athena-dist.mit.edu/pub/ATHENA/${PN}/${P}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~x86 ~ppc ~sparc ~hppa ~amd64 alpha ia64"

DEPEND="virtual/glibc"

src_unpack() {
	unpack ${A}
	cd ${S}

	filter-flags -fstack-protector

	#Patches stolen from RH
	epatch ${FILESDIR}/hesiod-${PV}-redhat.patch.gz
	autoconf || die "autoconf failed"

	for manpage in *.3
	do
		if grep -q '^\.so man3/hesiod.3' ${manpage}
		then
			echo .so hesiod.3 > ${manpage}
		elif grep -q '^\.so man3/hesiod_getmailhost.3' ${manpage}
		then
			echo .so hesiod_getmailhost.3 > ${manpage}
		elif grep -q '^\.so man3/hesiod_getpwnam.3' ${manpage}
		then
			echo .so hesiod_getpwnam.3 > ${manpage}
		elif grep -q '^\.so man3/hesiod_getservbyname.3' ${manpage}
		then
			echo .so hesiod_getservbyname.3 > ${manpage}
		fi
	done
}

src_install() {
	make DESTDIR=${D} install || die
}
