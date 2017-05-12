# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/bluez-utils/bluez-utils-2.3-r1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit eutils

DESCRIPTION="bluetooth utilities"
HOMEPAGE="http://bluez.sourceforge.net/"
SRC_URI="http://bluez.sourceforge.net/download/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86"
IUSE="gtk"
RDEPEND=">=net-wireless/bluez-libs-2.4
	gtk? ( >=dev-python/pygtk-0.6.11 )"

DEPEND="sys-devel/bison
	sys-devel/flex
	>=sys-apps/sed-4
	${RDEPEND}"

src_unpack() {
	unpack ${A}
	cd ${S}

	# patch to fix bluepin to use pygtk1
	epatch ${FILESDIR}/${P}-bluepin.patch
	epatch ${FILESDIR}/${P}-rfcomm_fflush.patch

	# Fix some installation locations

	for dir in rfcomm tools; do
		mv -f $dir/Makefile.in ${T}/Makefile.in
		sed -e "s:\$(prefix)/usr/share/man:\@mandir\@:" \
			${T}/Makefile.in > $dir/Makefile.in;
	done

	mv -f hcid/Makefile.in ${T}/Makefile.in
	sed -e "s:\$(prefix)/etc/bluetooth:/etc/bluetooth:" \
		${T}/Makefile.in > hcid/Makefile.in

	if ! use gtk; then
		mv -f scripts/Makefile.in ${T}/Makefile.in
		sed -e "s:= bluepin:= :" \
			${T}/Makefile.in > scripts/Makefile.in
	fi
}

src_compile() {
	econf || die "econf failed"
	emake || die
}

src_install() {
	make DESTDIR=${D} install || die
	dodoc README

	sed -e "s:\(pin_helper \).*:\1/etc/bluetooth/pin;:" \
		-e "s:security auto;:security user;:" \
		-i ${D}/etc/bluetooth/hcid.conf

	exeinto /etc/init.d
	newexe ${FILESDIR}/bluetooth.rc bluetooth

	exeinto /etc/bluetooth
	newexe ${FILESDIR}/pin.sample pin
	fperms 0700 /etc/bluetooth/pin
}

pkg_postinst() {
	einfo ""
	einfo "A startup script has been installed in /etc/init.d/bluetooth."
	einfo "RFComm devices are found in /dev/bluetooh/rfcomm/* instead of /dev/rfcomm*"
	einfo "If you need to set a PIN, edit /etc/bluetooth/pin"
	einfo ""
}
