# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/psh/psh-1.8.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit perl-module

DESCRIPTION="Combines the interactive nature of a Unix shell with the power of Perl"
SRC_URI="http://www.focusresearch.com/gregor/psh/${P}.tar.gz"
HOMEPAGE="http://www.focusresearch.com/gregor/psh/"
LICENSE="Artistic | GPL-2"
SLOT="0"
KEYWORDS="x86 ~ppc sparc alpha ia64"

DEPEND=">=dev-lang/perl-5"

myinst="SITEPREFIX=${D}/usr"
