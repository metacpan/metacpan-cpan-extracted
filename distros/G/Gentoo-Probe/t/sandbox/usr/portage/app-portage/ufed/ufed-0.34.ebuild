# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/ufed/ufed-0.34.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="Gentoo Linux USE flags editor"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ppc sparc mips alpha arm hppa amd64 ia64 ppc64"
IUSE=""

RDEPEND="dev-lang/perl
	dev-util/dialog
	dev-perl/TermReadKey"
DEPEND=""

src_install() {
	newsbin ufed.pl ufed || die
	doman ufed.8
	dodoc ChangeLog
}
