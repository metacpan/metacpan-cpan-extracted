# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/hostap-driver/hostap-driver-0.1.3.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

# pcmcia eclass inherits eutils
inherit pcmcia eutils

DESCRIPTION="HostAP wireless drivers"
HOMEPAGE="http://hostap.epitest.fi/"
SRC_URI="${SRC_URI} http://hostap.epitest.fi/releases/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="${KV}"
KEYWORDS="x86"
IUSE="${IUSE} hostap-nopci hostap-noplx"
DEPEND=">=net-wireless/wireless-tools-25"
RDEPEND="!net-wireless/hostap"

KMOD_PATH="/lib/modules/${KV}"

src_unpack() {
	check_KV
	unpack ${A}

	## unpack the pcmcia-cs sources if needed
	pcmcia_src_unpack

	cd ${S}
	epatch "${FILESDIR}/${P}.firmware.diff.bz2"

	## set compiler options
	sed -i -e "s:gcc:${CC}:" ${S}/Makefile
	# sed -i -e "s:-O2:${CFLAGS}:" "${S}/Makefile" # improper CFLAGS could cause unresolved symbols in the modules

	## fix for new coreutils (#31801)
	sed -i -e "s:tail -1:tail -n 1:" ${S}/Makefile

	## set correct pcmcia path (PCMCIA_VERSION gets set from pcmcia_src_unpack)
	if [ -n "${PCMCIA_VERSION}" ]; then
		sed -i -e "s:^PCMCIA_PATH=:PCMCIA_PATH=${PCMCIA_SOURCE_DIR}:" ${S}/Makefile
	fi
}

src_compile() {
	## configure pcmcia
	pcmcia_configure

	cd ${S}

	einfo "Building hostap-driver for kernel version: ${KV}"
	case ${KV} in
		2.[34].*)
			local mydrivers

			use pcmcia && mydrivers="${mydrivers} pccard"
			use hostap-nopci || mydrivers="${mydrivers} pci"
			use hostap-noplx || mydrivers="${mydrivers} plx"

			einfo "Building the following drivers: ${mydrivers}"
			emake EXTRA_CFLAGS="-DPRISM2_DOWNLOAD_SUPPORT" ${mydrivers} || die "make failed"
			;;
		2.[56].*)
			unset ARCH
			emake EXTRA_CFLAGS="-DPRISM2_DOWNLOAD_SUPPORT" all || die "make failed"
			;;
		*)
			eerror "Unsupported kernel version: ${KV}"
			die
			;;
	esac
}

src_install() {
	## kernel 2.6 has a different module file name suffix
	case ${KV} in
		2.[34].*)
			kobj=o
			;;
		2.[56].*)
			kobj=ko
	esac

	dodir ${KMOD_PATH}/net
	cp ${S}/driver/modules/{hostap,hostap_crypt_wep}.${kobj} \
		${D}${KMOD_PATH}/net/

	if use pcmcia >&/dev/null; then
		dodir ${KMOD_PATH}/pcmcia
		dodir /etc/pcmcia
		cp ${S}/driver/modules/hostap_cs.${kobj} ${D}/${KMOD_PATH}/pcmcia/
		cp ${S}/driver/etc/hostap_cs.conf ${D}/etc/pcmcia/
		if [ -r /etc/pcmcia/prism2.conf ]; then
			einfo "You may need to edit or remove /etc/pcmcia/prism2.conf"
			einfo "This is usually a result of conflicts with the"
			einfo "linux-wlan-ng drivers."
		fi
	fi

	if ! use hostap-nopci >&/dev/null; then
		cp ${S}/driver/modules/hostap_pci.${kobj} \
			${D}${KMOD_PATH}/net/
	fi

	if ! use hostap-noplx >&/dev/null; then
		cp ${S}/driver/modules/hostap_plx.${kobj} \
			${D}${KMOD_PATH}/net/
	fi
	dodoc README ChangeLog
}

pkg_postinst(){
	einfo "Checking kernel module dependancies"
	cd /usr/src/linux && make _modinst_post ## depmod
}
