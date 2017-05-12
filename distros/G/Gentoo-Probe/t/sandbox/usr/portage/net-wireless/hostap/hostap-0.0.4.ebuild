# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/hostap/hostap-0.0.4.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit eutils

DESCRIPTION="HostAP wireless drivers"
HOMEPAGE="http://hostap.epitest.fi/"

MY_PCMCIA="pcmcia-cs-3.2.1"
PATCH_3_2_2="${MY_PCMCIA}-3.2.2.diff.gz"
PATCH_3_2_3="${MY_PCMCIA}-3.2.3.diff.gz"
PATCH_3_2_4="${MY_PCMCIA}-3.2.4.diff.gz"

SRC_URI="http://hostap.epitest.fi/releases/${P}.tar.gz
		pcmcia? ( mirror://sourceforge/pcmcia-cs/${MY_PCMCIA}.tar.gz )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_2} )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_3} )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_4} )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"

IUSE="pcmcia hostap-nopci hostap-noplx"

DEPEND=">=net-wireless/wireless-tools-25
		pcmcia? ( >=sys-apps/pcmcia-cs-3.2.1* )"

LIB_PATH="/lib/modules/${KV}"

src_unpack() {
	check_KV
	unpack ${P}.tar.gz

	if use pcmcia; then
		unpack ${MY_PCMCIA}.tar.gz
		cd ${WORKDIR}/${MY_PCMCIA}
		if [ -z "`has_version =sys-apps/pcmcia-cs-3.2.4*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_4}
		elif [ -z "`has_version =sys-apps/pcmcia-cs-3.2.3*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_3}
		elif [ -z "`has_version =sys-apps/pcmcia-cs-3.2.2*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_2}
		fi
	fi


	cd ${S}
	mv Makefile ${T}
	sed -e "s:gcc:${CC}:" \
		-e "s:-O2:${CFLAGS}:" \
		-e "s:\$(EXTRA_CFLAGS):\$(EXTRA_CFLAGS) -DPRISM2_HOSTAPD:" \
		${T}/Makefile > Makefile

	if use pcmcia || [[ "${HOSTAP_DRIVERS}" == *pccard* ]]; then
		mv Makefile ${T}
		sed -e "s:^PCMCIA_PATH=:PCMCIA_PATH=${WORKDIR}/${MY_PCMCIA}:" \
			${T}/Makefile > Makefile
	fi

	cd ${S}/hostapd
	mv Makefile ${T}
	sed -e "s:gcc:${CC}:" \
		-e "s:-O2:${CFLAGS}:" \
		${T}/Makefile > Makefile
}

src_compile() {

	local mydrivers

	use pcmcia && mydrivers="${mydrivers} pccard"
	use hostap-nopci || mydrivers="${mydrivers} pci"
	use hostap-noplx || mydrivers="${mydrivers} plx"

	# Build the drivers
	einfo "Building the folowing drivers: ${mydrivers}"
	emake ${mydrivers} || die

	# Make the hostapd daemon
	cd ${S}/hostapd
	emake || die

	# Make the little wlansniff utility
	cd ${S}/sniff
	emake || die
}

src_install() {
	dodir ${LIB_PATH}/net
	cp ${S}/driver/modules/{hostap.o,hostap_crypt.o,hostap_crypt_wep.o}\
		${D}${LIB_PATH}/net/

	if use pcmcia; then
		dodir ${LIB_PATH}/pcmcia
		dodir /etc/pcmcia
		cp ${S}/driver/modules/hostap_cs.o ${D}/${LIB_PATH}/pcmcia/
		cp ${S}/driver/etc/hostap_cs.conf ${D}/etc/pcmcia/
		if [ -r /etc/pcmcia/prism2.conf ]; then
			einfo "You may need to edit or remove /etc/pcmcia/prism2.conf"
			einfo "This is usually a result of conflicts with the"
			einfo "linux-wlan-ng drivers."
		fi
	fi

	if ! use hostap-nopci; then
		cp ${S}/driver/modules/hostap_pci.o\
			${D}${LIB_PATH}/net/
	fi

	if ! use hostap-noplx; then
		cp ${S}/driver/modules/hostap_plx.o\
			${D}${LIB_PATH}/net/
	fi

	dodoc FAQ README driver_source.txt ChangeLog

	dosbin hostapd/hostapd
	dosbin sniff/wlansniff
	newdoc sniff/README README.wlansniff
}
pkg_postinst(){
	/sbin/depmod -a
}
