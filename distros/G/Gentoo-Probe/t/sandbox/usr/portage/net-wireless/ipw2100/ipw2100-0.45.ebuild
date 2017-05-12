# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/ipw2100/ipw2100-0.45.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit kernel-mod eutils

FW_VERSION="1.1"

DESCRIPTION="Driver for the Intel Centrino wireless chipset"

HOMEPAGE="http://ipw2100.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tgz
		mirror://gentoo/${PN}-fw-${FW_VERSION}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"

IUSE=""
DEPEND=""
RDEPEND=">=sys-apps/hotplug-20030805-r2
	 >=net-wireless/hostap-driver-0.1.3"

src_unpack() {
	if ! egrep "^CONFIG_FW_LOADER=[ym]" ${ROOT}/usr/src/linux/.config >/dev/null
	then
		eerror ""
		eerror "New versions of ${PN} require firmware loader support from"
		eerror "your kernel. This can be found in Device Drivers --> Generic"
		eerror "Driver Support on 2.6 or in Library Routines on 2.4 kernels."
		die "Firmware loading support not detected."
	fi

	unpack ${A}
	kernel-mod_getversion

	cd ${S}
	mkdir -p hostap-driver-0.1.3/driver/modules
	cp ${FILESDIR}/hostap_crypt.h hostap-driver-0.1.3/driver/modules
}

src_compile() {
	unset ARCH
	emake KSRC=${ROOT}/usr/src/linux HOSTAP=hostap-driver-0.1.3 all || die
}

src_install() {
	if [ ${KV_MINOR} -gt 4 ]
	then
		KV_OBJ="ko"
	else
		KV_OBJ="o"
	fi

	dodoc ISSUES README.ipw2100 CHANGES

	insinto /lib/modules/${KV}/net
	doins ipw2100.${KV_OBJ} av5100.${KV_OBJ} pbe5.${KV_OBJ}

	insinto /usr/lib/hotplug/firmware
	doins ${WORKDIR}/${PN}-${FW_VERSION}.fw
	doins ${WORKDIR}/${PN}-${FW_VERSION}-p.fw
	doins ${WORKDIR}/${PN}-${FW_VERSION}-i.fw
	doins ${WORKDIR}/LICENSE
}

pkg_postinst() {
	if [ ${KV_MINOR} -gt 4 ]
	then
		KV_OBJ="ko"
	else
		KV_OBJ="o"
	fi

	einfo "Checking kernel module dependancies"
	test -r "${ROOT}/usr/src/linux/System.map" && \
		depmod -ae -F "${ROOT}/usr/src/linux/System.map" -b "${ROOT}" -r ${KV}

	if [ ! -f ${ROOT}/lib/modules/${KV}/net/hostap_crypt_wep.${KV_OBJ} ]
	then
		eerror ""
		eerror "Modules for hostap-driver not found!"
		eerror "For WEP to work, you need the hostap-driver modules available for your kernel"
		eerror "If you upgrade kernels, you need to re-emerge BOTH ipw2100 and hostap-driver"
		eerror "to ensure that all the needed kernel modules are present!"
		eerror ""
	fi
}
