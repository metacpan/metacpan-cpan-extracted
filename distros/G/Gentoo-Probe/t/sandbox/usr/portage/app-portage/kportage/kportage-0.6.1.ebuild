# Copyright 1999-2003 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/kportage/kportage-0.6.1.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit kde-base
need-kde 3

DESCRIPTION="A graphical frontend for portage"
SRC_URI="http://freesoftware.fsf.org/download/${PN}/${PN}.pkg/${PV/.1//}/${P}.tar.bz2"
HOMEPAGE="http://www.freesoftware.fsf.org/kportage/"

LICENSE="GPL-2"
KEYWORDS="x86 ppc sparc"

DEPEND=">=sys-apps/portage-2.0.46-r12
	>=dev-lang/python-2.2.2
	>=x11-libs/qt-3.1"

IUSE=""

src_compile() {
	kde_src_compile myconf configure
	emake CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" || die
}
