# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/bluez-kernel/bluez-kernel-2.3.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="bluetooth kernel drivers"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~ppc"
IUSE=""
DEPEND=""
S="${WORKDIR}/${P}"

src_unpack() {
	unpack ${A} || die "unpack failed"
	cd ${S} || die

	# don't let the install target try to run depmod
	# and 'bnep' fails to compile

	mv Makefile.in Makefile.in.orig
	sed -e '25d' \
		-e 's|bnep\s*||' \
		Makefile.in.orig > Makefile.in
}

src_compile() {
	econf || die "econf failed"
	emake || die
}

src_install() {
	make DESTDIR=${D} install || die
}

pkg_setup() {
	# bluez shouldn't be used with the std linux bluetooth usb driver
	if [ -f /usr/src/linux/.config ]; then
		if [[ `grep ^CONFIG_USB_BLUETOOTH=y /usr/src/linux/.config` ]]; then
			einfo "You must disable the USB bluetooth driver in the linux kernel"
			einfo "before running bluez"
			die "Bad kernel config"
		elif [[ `grep ^CONFIG_USB_BLUETOOTH=m /usr/src/linux/.config` ]]; then
			einfo "Warning: bluez should not be used with the USB bluetooth driver"
			einfo "Warning: in the linux kernel"
		fi
	fi
}

pkg_postinst() {
	if [ "${ROOT}" = / ]
	then
		[ -x /usr/sbin/update-modules ] && /usr/sbin/update-modules
	fi
}
