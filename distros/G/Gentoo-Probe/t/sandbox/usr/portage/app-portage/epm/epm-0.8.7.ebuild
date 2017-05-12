# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/epm/epm-0.8.7.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="rpm workalike for Gentoo Linux"
SRC_URI="http://www.gentoo.org/~agriffis/epm/${P}.tar.gz"
HOMEPAGE="http://www.gentoo.org/~agriffis/epm/"
KEYWORDS="x86 amd64 ppc sparc alpha mips ia64"
SLOT="0"
LICENSE="GPL-2"
DEPEND=">=dev-lang/perl-5"

src_compile() {
	pod2man epm > epm.1 || die "pod2man failed"
}

src_install () {
	dobin epm
	doman epm.1
}
