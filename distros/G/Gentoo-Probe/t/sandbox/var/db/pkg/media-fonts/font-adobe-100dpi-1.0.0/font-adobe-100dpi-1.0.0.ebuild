# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/var/db/pkg/media-fonts/font-adobe-100dpi-1.0.0/font-adobe-100dpi-1.0.0.ebuild,v 1.1 2007/10/13 03:28:17 rich Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular


DESCRIPTION="X.Org Adobe bitmap fonts"
KEYWORDS="alpha amd64 arm hppa ia64 mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
RDEPEND=""
DEPEND="${RDEPEND}
	x11-apps/bdftopcf
	media-fonts/font-util"

CONFIGURE_OPTIONS="--with-mapfiles=${XDIR}/share/fonts/util"
