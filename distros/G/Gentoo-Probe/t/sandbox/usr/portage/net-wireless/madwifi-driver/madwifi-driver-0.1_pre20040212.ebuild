# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/madwifi-driver/madwifi-driver-0.1_pre20040212.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="Wireless driver for Atheros chipset a/b/g cards"
HOMEPAGE="http://madwifi.sourceforge.net/"

# Point to any required sources; these will be automatically downloaded by
# Portage.
SRC_URI="mirror://gentoo/$P.tar.bz2"

LICENSE="GPL-2"
SLOT="0"

KEYWORDS="~x86"
IUSE=""
DEPEND=""

S=${WORKDIR}

pkg_setup() {

	if [[ "${KV}" > "2.5" ]] ; then
		cd /usr/src/linux
		./scripts/modpost ./vmlinux
	fi

}

src_unpack() {
	check_KV
	unpack ${A}

	einfo "${KV}"

	cd ${S}
	mv Makefile.inc ${T}
	sed -e "s:\$(shell uname -r):${KV}:" \
		-e "s:\${DEPTH\}/../:/usr/src/:" \
		${T}/Makefile.inc > Makefile.inc
}

src_compile() {
	make clean
	make || die
}

src_install() {
	dodir /lib/modules/${KV}/net
	insinto /lib/modules/${KV}/net

	# dealing with 2.6.0 kernel modules .ko naming 
	if [[ "${KV}" > "2.5" ]] ; then
#		ewarn "Kernel Version 2.5 or higher"
		doins ${S}/wlan/wlan.ko ${S}/ath_hal/ath_hal.ko ${S}/driver/ath_pci.ko
	else
#		ewarn "Kernel Version under 2.5"
		doins ${S}/wlan/wlan.o ${S}/ath_hal/ath_hal.o ${S}/driver/ath_pci.o
	fi

	dodoc README
}

pkg_postinst() {

	depmod -a

	einfo ""
	einfo "The madwifi drivers create an interface named 'athX'"
	einfo "Create /etc/init.d/net.ath0 and add a line for athX"
	einfo "in /etc/conf.d/net like 'iface_ath0=\"dhcp\"'"
	einfo ""
}
