# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/hostap-driver/hostap-driver-0.1.2-r2.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

# pcmcia eclass inherits eutils
inherit pcmcia eutils

DESCRIPTION="HostAP wireless drivers"
HOMEPAGE="http://hostap.epitest.fi/"
SRC_URI="${SRC_URI} http://hostap.epitest.fi/releases/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="${IUSE} hostap-nopci hostap-noplx"
DEPEND=">=net-wireless/wireless-tools-25"

RDEPEND="!net-wireless/hostap"

LIB_PATH="/lib/modules/${KV}"

src_unpack() {
	check_KV
	unpack ${A}

	# Unpack the pcmcia-cs sources if needed
	pcmcia_src_unpack

	cd ${S}
	epatch "${FILESDIR}/${P}.firmware.diff.bz2"

	## set compiler options
	sed -i -e "s:gcc:${CC}:" ${S}/Makefile
	# sed -i -e "s:-O2:${CFLAGS}:" "${S}/Makefile" # improper CFLAGS could cause unresolved symbols in the modules

	## fix for new coreutils (#31801)
	sed -i -e "s:tail -1:tail -n 1:" ${S}/Makefile


	# If we unpacked them, add the path to the Makefile
	if [ -n "${PCMCIA_SOURCE_DIR}" ]
	then
		sed -i -e "s:^PCMCIA_PATH=:PCMCIA_PATH=${PCMCIA_SOURCE_DIR}:" ${S}/Makefile
	fi
}

src_compile() {
	# Configure using pcmcia.eclass
	pcmcia_configure

	cd ${S}
	okvminor="${KV#*.}" ; okvminor="${okvminor%%.*}"

	# 2.6 needs just to do "make all"
	if [ "${okvminor}" -lt 5 ]; then
		local mydrivers

		use pcmcia && mydrivers="${mydrivers} pccard"
		use hostap-nopci || mydrivers="${mydrivers} pci"
		use hostap-noplx || mydrivers="${mydrivers} plx"

		einfo "Building the following drivers: ${mydrivers}"
		emake EXTRA_CFLAGS="-DPRISM2_DOWNLOAD_SUPPORT" ${mydrivers} || die
	else
		unset ARCH
		emake EXTRA_CFLAGS="-DPRISM2_DOWNLOAD_SUPPORT" all || die
	fi

}

src_install() {
	# Magic for different kernel module extensions

	okvminor="${KV#*.}" ; okvminor="${okvminor%%.*}"
	if [ "${okvminor}" -gt 5 ]; then
		kobj=ko
	else
		kobj=o
	fi

	dodir ${LIB_PATH}/net
	cp ${S}/driver/modules/{hostap,hostap_crypt_wep}.${kobj} \
		${D}${LIB_PATH}/net/

	if use pcmcia >&/dev/null; then
		dodir ${LIB_PATH}/pcmcia
		dodir /etc/pcmcia
		cp ${S}/driver/modules/hostap_cs.${kobj} ${D}/${LIB_PATH}/pcmcia/
		cp ${S}/driver/etc/hostap_cs.conf ${D}/etc/pcmcia/
		if [ -r /etc/pcmcia/prism2.conf ]; then
			einfo "You may need to edit or remove /etc/pcmcia/prism2.conf"
			einfo "This is usually a result of conflicts with the"
			einfo "linux-wlan-ng drivers."
		fi
	fi

	if ! use hostap-nopci >&/dev/null; then
		cp ${S}/driver/modules/hostap_pci.${kobj} \
			${D}${LIB_PATH}/net/
	fi

	if ! use hostap-noplx >&/dev/null; then
		cp ${S}/driver/modules/hostap_plx.${kobj} \
			${D}${LIB_PATH}/net/
	fi
	dodoc README ChangeLog
}

pkg_postinst(){
	depmod -a
	einfo "Checking kernel module dependancies"
}
