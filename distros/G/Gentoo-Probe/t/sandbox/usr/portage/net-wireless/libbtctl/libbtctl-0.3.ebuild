# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/libbtctl/libbtctl-0.3.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit gnome2

DESCRIPTION="A GObject wrapper for Bluetooth functionality"
HOMEPAGE="http://usefulinc.com/software/gnome-bluetooth/"
SRC_URI="http://usefulinc.com/software/gnome-bluetooth/releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~sparc"
IUSE=""

RDEPEND=">=dev-libs/glib-2
	>=net-wireless/bluez-utils-2
	>=net-wireless/bluez-libs-2
	>=net-wireless/bluez-sdp-1"

DEPEND="${RDEPEND}
	dev-util/intltool
	dev-util/pkgconfig"

MAKEOPTS="${MAKEOPTS} -j1"
DOCS="README NEWS ChangeLog AUTHORS COPYING"
