# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2

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
	dobin ${S}/utils/ndiswrapper

	dodoc ${S}/README ${S}/INSTALL ${S}/AUTHORS

	insinto /lib/modules/${KV}/misc
	doins ${S}/driver/ndiswrapper.${KV_OBJ}

	insinto /etc/modules.d
	newins ${FILESDIR}/${P}-modules.d ndiswrapper

	dodir /etc/ndiswrapper
}

pkg_postinst() {
	kernel-mod_pkg_postinst

	einfo
	einfo "ndiswrapper requires .inf and .sys files from a Windows(tm) driver"
	einfo "to function. Put these somewhere like /usr/lib/hotplug/drivers,"
	einfo "run 'ndiswrapper -i /usr/lib/hotplug/drivers/foo.inf', edit"
	einfo "/etc/modules.d/ndiswrapper to add the path to subdirectory in"
	einfo "/etc/ndiswrapper, then run 'update-modules'."
	einfo
}

pkg_config() {
	ewarn "New versions of ndiswrapper do not require you to run config"

	if [ ! -f "/etc/modules.d/ndiswrapper" ]
	then
		eerror "/etc/modules.d/ndiswrapper not found. Please re-emerge"
		eerror "${PN} to have this file installed, then re-run this script"
		die "Driver configuration file not found"
	fi

	I=`lspci -n | grep 'Class 0280:' | cut -d' ' -f4`

	if [ -z "${I}" ]
	then
		die "No suitable devices found"
	fi
}
