# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/genlop/genlop-0.20.2.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="A nice emerge.log parser"
HOMEPAGE="http://pollycoke.org/genlop.html"
SRC_URI="http://pollycoke.org/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc alpha hppa amd64 mips"

RDEPEND=">=dev-lang/perl-5.8.0-r12
		>=dev-perl/Time-Duration-1.02"

src_install() {
	dobin genlop || die
	dodoc README Changelog
	doman genlop.1
	dodir /usr/share/bash-completion
	insinto /usr/share/bash-completion
	newins genlop.bash-completion genlop
}
