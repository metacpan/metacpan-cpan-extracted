# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-portage/gentoolkit-dev/gentoolkit-dev-0.2.0_pre3.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

DESCRIPTION="Collection of developer scripts for Gentoo"
HOMEPAGE="http://www.gentoo.org/~karltk/projects/gentoolkit/"
SRC_URI="http://dev.gentoo.org/~karltk/projects/gentoolkit/releases/${P}.tar.gz"
#SRC_URI="mirror://gentoo/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ppc ~sparc ~mips alpha arm ~hppa amd64 ~ia64 ~ppc64 s390"

DEPEND=">=sys-apps/portage-2.0.50
	>=dev-lang/python-2.0
	>=dev-util/dialog-0.7
	>=dev-lang/perl-5.6
	>=sys-apps/grep-2.5-r1"

src_install() {
	make DESTDIR=${D} install-gentoolkit-dev
}
