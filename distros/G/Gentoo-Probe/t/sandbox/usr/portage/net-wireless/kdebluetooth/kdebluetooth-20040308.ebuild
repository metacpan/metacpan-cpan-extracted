# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/kdebluetooth/kdebluetooth-20040308.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit kde
need-kde 3

DESCRIPTION="KDE Bluetooth Framework"
HOMEPAGE="http://kde-bluetooth.sourceforge.net/"
SRC_URI="http://members.xoom.virgilio.it/motaboy/kdebluetooth-${PV}.tar.bz2"

LICENSE="GPL-2"
KEYWORDS="~x86"
RESTRICT="nomirror"

DEPEND=">=dev-libs/openobex-1
	>=net-wireless/bluez-libs-2
	>=net-wireless/bluez-sdp-1"

need-automake 1.6
need-autoconf 2.5

src_install() {
	kde_src_install
}

pkg_postinst() {
	einfo "This new version of kde-bluetooth provide a replacement for the"
	einfo "standard bluepin program called \"kbluepin\"!!! "
	einfo ""
	einfo "If you want to use it, you have to edit your \"/etc/bluetooth/hcid.conf\" "
	einfo "and change the line \"pin_helper oldbluepin;\" with \"pin_helper /usr/bin/kbluepin;\""
	einfo "Then restart hcid to make the change working"
}
