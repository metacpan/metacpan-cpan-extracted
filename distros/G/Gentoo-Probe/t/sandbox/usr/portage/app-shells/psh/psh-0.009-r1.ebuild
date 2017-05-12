# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/psh/psh-0.009-r1.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="Combines the interactive nature of a Unix shell with the power of Perl"
SRC_URI="http://www.focusresearch.com/gregor/psh/${P}.tar.gz"
HOMEPAGE="http://www.focusresearch.com/gregor/psh/"
LICENSE="Artistic | GPL-2"
KEYWORDS="x86 ppc sparc"
SLOT="0"

DEPEND=">=dev-lang/perl-5"

src_compile() {
	perl Makefile.PL

	make || die
}

src_install() {
	make PREFIX=${D}/usr \
		prefix=${D}/usr \
		INSTALLMAN3DIR=${D}/usr/share/man/man3 \
		install || die

	dodoc COPYRIGHT HACKING MANIFEST README* RELEASE TODO
	dodoc examples/complete-examples
}








