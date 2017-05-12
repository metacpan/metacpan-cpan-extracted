# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/media-fonts/font-adobe-75dpi/font-adobe-75dpi-1.0.0.ebuild,v 1.2 2008/05/10 11:05:29 rich Exp $

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular


DESCRIPTION="BigReqs prototype headers"
RESTRICT="mirror"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
RDEPEND=""
DEPEND="${RDEPEND}
	x11-apps/bdftopcf
	media-fonts/font-util"

CONFIGURE_OPTIONS="--with-mapfiles=${XDIR}/share/fonts/util"
