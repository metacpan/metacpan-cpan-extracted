# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/genlop/genlop-0.16.3.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="A nice emerge.log parser"
HOMEPAGE="http://freshmeat.net/projects/genlop/"
SRC_URI="http://pollycoke.org/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc mips alpha hppa amd64"

DEPEND="app-arch/tar
	app-arch/gzip"
RDEPEND=">=dev-lang/perl-5.8.0-r10"

src_install() {
	dobin genlop || die
	dodoc README
}
