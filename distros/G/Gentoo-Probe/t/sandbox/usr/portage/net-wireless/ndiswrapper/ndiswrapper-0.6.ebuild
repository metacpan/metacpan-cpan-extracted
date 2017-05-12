# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/ndiswrapper/ndiswrapper-0.6.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit kernel-mod

S=${WORKDIR}/${P}
DESCRIPTION="Wrapper for using Windows drivers for some wireless cards"
HOMEPAGE="http://ndiswrapper.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE=""
DEPEND="sys-devel/flex"

src_unpack() {
	check_KV
	kernel-mod_getversion
	unpack ${A}

	if [ ${KV_MINOR} -eq 4 ]  && [ ${KV_PATCH} -lt 23 ]
	then
		eerror "${P} requires a 2.4 kernel version of at"
		eerror "least 2.4.23. You can either upgrade your kernel,"
		eerror "Or use the ndiswrapper-0.3 ebuild."
		die "Kernel version not supported"
	fi

	# Fix path to kernel and KVERS
	sed -i -e "s:^KSRC.*:KSRC=${ROOT}/usr/src/linux:" \
		-e "s:^KVERS.*:KVERS=${KV_MAJOR}${KV_MINOR}:" \
		${S}/driver/Makefile
}

src_compile() {
	# Unset ARCH for 2.5/2.6 kernel compiles
	unset ARCH
	emake || die
}

src_install() {
	if [ ${KV_MINOR} -gt 4 ]
	then
		KV_OBJ="ko"
	else
		KV_OBJ="o"
	fi

	dobin ${S}/utils/loadndisdriver
	dodoc ${S}/README ${S}/INSTALL ${S}/AUTHORS

	insinto /lib/modules/${KV}/misc
	doins ${S}/driver/ndiswrapper.${KV_OBJ}

	insinto /etc/modules.d
	newins ${FILESDIR}/ndiswrapper.modules.d ndiswrapper
}

pkg_postinst() {
	einfnfo "Checking kernel module dependancies"
	test -r "${ROOT}/${KV_OUTPUT}/System.map" && \
		depmod -ae -F "${ROOT}/${KV_OUTPUT}/System.map" -b "${ROOT}" -r ${KV}

	einfo "Part of the ${PN} module configuration can be done by running"
	einfo "# ebuild /var/db/pkg/net-wiress/${P}/${P}.ebuild config"
	einfo "Please consult /etc/modules.d/ndiswrapper to finish"
	einfo "configuring the driver"
	einfo
	einfo "In particular, ndiswrapper requires .inf and .sys files from"
	einfo "a Windows(tm) driver to function. Put these somewhere like"
	einfo "/usr/lib/hotplug/drivers, edit /etc/modules.d/ndiswrapper to match,"
	einfo "then run 'update-modules'"
	einfo
}

pkg_config() {
	if [ ! -f "/etc/modules.d/ndiswrapper" ]
	then
		eerror "/etc/modules.d/ndiswrapper not found. Please re-emerge"
		eerror "${PN} to have this file installed, then re-run this script"
		die "Driver configuration file not found"
	fi

	if ! egrep "VENDORID" /etc/modules.d/ndiswrapper
	then
		eerror "/etc/modules.d/ndiswrapper doesn't appear to be the one"
		eerror "distributed by the ${PN} ebuild. To use this config script,"
		eerror "Please re-emerge ${PN} and then re-run this script."
		die "Driver configuration file not usable"
	else
		einfo "Found acceptable config file at /etc/modules.d/ndiswrapper"
	fi

	if [ `lspci -n | grep 'Class 0280:' | wc -l` -gt 1 ]
	then
		eerror "More than one suitable device detected. This script"
		eerror "will only work with one suitable device present."
		die "Too many potential devices found"
	fi

	I=`lspci -n | grep 'Class 0280:' | cut -d' ' -f4`

	if [ -z "${I}" ]
	then
		die "No suitable devices found"
	fi

	VENDOR=`echo $I | cut -d':' -f1`
	DEVICEID=`echo $I | cut -d':' -f2`

	einfo "Setting the vendor ID to ${VENDOR} and the device ID to ${DEVICEID}"
	sed -i -e "s:VENDORID:${VENDOR}:" \
		-e "s:DEVICEID:${DEVICEID}:" \
		/etc/modules.d/ndiswrapper
}
