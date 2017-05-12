# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/kwavecontrol/kwavecontrol-0.3.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit kde
need-kde 3
newdepend "net-wireless/wireless-tools"
PATCHES="${FILESDIR}/${P}-gentoo.diff"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"
HOMEPAGE="http://kwc.progeln.de/"
LICENSE="GPL-2"
KEYWORDS="x86 ~ppc"
IUSE=""
DESCRIPTION="KWaveControl is a little tool for WaveLAN wireless cards based on the wireless extensions."
