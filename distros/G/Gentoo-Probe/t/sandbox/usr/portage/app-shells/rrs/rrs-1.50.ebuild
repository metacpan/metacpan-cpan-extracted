# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/rrs/rrs-1.50.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit eutils

DESCRIPTION="Reverse Remote Shell"
HOMEPAGE="http://www.cycom.se/dl/rrs"
SRC_URI="http://www.cycom.se/uploads/36/17/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="x86 ~ppc"
IUSE="ssl"

DEPEND="ssl? ( dev-libs/openssl )
	virtual/glibc"

src_unpack() {
	unpack ${A}
	cd ${S}
	epatch ${FILESDIR}/${PV}-include-string.h.patch
}

src_compile() {
	local target=""
	use ssl || target="-nossl"

	emake generic${target} \
		LDEXTRA="-lstdc++" \
		CFLAGS="${CFLAGS}" || die "emake failed"
}

src_install() {
	dobin rrs
	dodoc CHANGES README
	doman rrs.1
}
