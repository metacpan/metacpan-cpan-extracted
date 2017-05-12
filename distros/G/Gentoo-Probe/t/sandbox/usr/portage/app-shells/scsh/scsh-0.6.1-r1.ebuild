# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/scsh/scsh-0.6.1-r1.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

DESCRIPTION="Unix shell embedded in Scheme"
SRC_URI="ftp://ftp.scsh.net/pub/scsh/0.6/${P}.tar.gz"
HOMEPAGE="http://www.scsh.net/"

SLOT="0"
LICENSE="as-is | BSD | GPL-2"
KEYWORDS="x86 ppc sparc"

DEPEND="virtual/glibc"

src_compile() {
	econf --prefix=/ \
		--libdir=/usr/lib \
		--includedir=/usr/include \
		|| die
	make || die
}

src_install() {
	einstall \
		prefix=${D} \
		htmldir=${D}/usr/share/doc/${PF}/html \
		incdir=${D}/usr/include \
		mandir=${D}/usr/share/man/man1 \
		libdir=${D}/usr/lib \
		|| die
	dodoc RELEASE

	# Scsh doesn't have a very consistent documentation
	# structure. It's possible to override the placement of the
	# HTML during make install, but not the other documentation in
	# TeX, DVI and PS formats.

	# Thus we let scsh install the documentation and then clean up
	# afterwards.

	dosed "s:${D}::" /usr/share/man/man1/scsh.1

	dodir /usr/share/doc/${PF}
	mv ${D}/usr/lib/scsh/doc/* ${D}/usr/share/doc/${PF}
	rmdir ${D}/usr/lib/scsh/doc
	prepalldocs
}
