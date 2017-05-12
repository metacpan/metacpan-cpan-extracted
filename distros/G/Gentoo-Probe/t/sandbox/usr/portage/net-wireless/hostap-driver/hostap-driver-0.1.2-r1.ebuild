# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/hostap-driver/hostap-driver-0.1.2-r1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit eutils

DESCRIPTION="HostAP wireless drivers"
HOMEPAGE="http://hostap.epitest.fi/"
SRC_URI="http://hostap.epitest.fi/releases/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86"
IUSE="pcmcia hostap-nopci hostap-noplx"
DEPEND=">=net-wireless/wireless-tools-25
		pcmcia? ( >=sys-apps/pcmcia-cs-3.2.1 )"
RDEPEND="!net-wireless/hostap"
S="${WORKDIR}/${P}"
LIB_PATH="/lib/modules/${KV}"

src_unpack() {
	check_KV
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${P}.firmware.diff.bz2"

	## set compiler options
	sed -i -e "s:gcc:${CC}:" "${S}/Makefile"
	# sed -i -e "s:-O2:${CFLAGS}:" "${S}/Makefile" # improper CFLAGS could cause unresolved symbols in the modules

	## fix for new coreutils (#31801)
	sed -i -e "s:tail -1:tail -n 1:" "${S}/Makefile"

	## use pcmcia-cs sources if kernel tree pcmcia support is disabled and USE=pcmcia is set
	if use pcmcia >&/dev/null; then
		if egrep '^CONFIG_PCMCIA=[ym]' /usr/src/linux/.config >&/dev/null; then
			einfo "Kernel PCMCIA is enabled, skipping external pcmcia-cs sources"
		else
			einfo "Kernel PCMCIA is disabled, using external pcmcia-cs sources"
			## get ebuild of currently installed pcmcia-cs package
			PCMCIA_CS_EBUILD=(/var/db/pkg/sys-apps/pcmcia-cs-*/pcmcia-cs-*.ebuild) ## use bash globbing
			if [ ! -f "${PCMCIA_CS_EBUILD}" ]; then
				die "ERROR: pcmcia-cs ebuild (${PCMCIA_CS_EBUILD}) not found - are you sure pcmcia-cs is installed?"
			fi
			PCMCIA_CS_VER="${PCMCIA_CS_EBUILD##*/}" ## -> pcmcia-cs-VER.ebuild
			PCMCIA_CS_VER="${PCMCIA_CS_VER/pcmcia-cs-/}" ## strip 'pcmcia-cs-'
			PCMCIA_CS_VER="${PCMCIA_CS_VER/.ebuild/}" ## strip '.ebuild'
			PCMCIA_CS_VER="${PCMCIA_CS_VER/-r*/}" ## strip revision numbers
			PCMCIA_PATH="${WORKDIR}/pcmcia-cs-${PCMCIA_CS_VER}"
			sed -i -e "s:^PCMCIA_PATH=:PCMCIA_PATH=${PCMCIA_PATH}:" "${S}/Makefile"
			## unpack external pcmcia-cs sources
			cd "${WORKDIR}"
			unpack pcmcia-cs-${PCMCIA_CS_VER}.tar.gz ## unpack the pcmcia-cs sources to PCMCIA_PATH
			cd ${PCMCIA_PATH}
			## when not configured, pcmcia-cs spits out lots of errors (since 3.2.5)
			if ! ./Configure -n --srctree --kernel=/usr/src/linux >&/dev/null; then
				eerror "External pcmcia-cs configuration failed"
				die
			fi
		fi
	fi
}

src_compile() {

	local mydrivers

	use pcmcia && mydrivers="${mydrivers} pccard"
	use hostap-nopci || mydrivers="${mydrivers} pci"
	use hostap-noplx || mydrivers="${mydrivers} plx"

	einfo "Building the following drivers: ${mydrivers}"
	emake EXTRA_CFLAGS="-DPRISM2_DOWNLOAD_SUPPORT" ${mydrivers} || die
}

src_install() {
	dodir ${LIB_PATH}/net
	cp ${S}/driver/modules/{hostap.o,hostap_crypt_wep.o} \
		${D}${LIB_PATH}/net/
#	local myinstall="install_hostap install_crypt"

	if use pcmcia >&/dev/null; then
		dodir ${LIB_PATH}/pcmcia
		dodir /etc/pcmcia
		cp ${S}/driver/modules/hostap_cs.o ${D}/${LIB_PATH}/pcmcia/
		cp ${S}/driver/etc/hostap_cs.conf ${D}/etc/pcmcia/
		if [ -r /etc/pcmcia/prism2.conf ]; then
			einfo "You may need to edit or remove /etc/pcmcia/prism2.conf"
			einfo "This is usually a result of conflicts with the"
			einfo "linux-wlan-ng drivers."
		fi
#		myinstall="${myinstall} install_pccard"
	fi

	if ! use hostap-nopci >&/dev/null; then
		cp ${S}/driver/modules/hostap_pci.o \
			${D}${LIB_PATH}/net/
#		myinstall="${myinstall} install_pci"
	fi

	if ! use hostap-noplx >&/dev/null; then
		cp ${S}/driver/modules/hostap_plx.o \
			${D}${LIB_PATH}/net/
#		myinstall="${myinstall} install_plx"
	fi
#	emake DESTDIR="${D}" ${myinstall}
	dodoc README ChangeLog
}
pkg_postinst(){
	einfo "Checking kernel module dependancies"
	cd /usr/src/linux && make _modinst_post ## depmod
}
