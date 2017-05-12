# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/linux-wlan-ng/linux-wlan-ng-0.2.0-r3.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit pcmcia

IUSE="${IUSE} build usb"

DESCRIPTION="The linux-wlan Project"
SRC_URI="${SRC_URI}
		ftp://ftp.linux-wlan.org/pub/linux-wlan-ng/${P}.tar.gz
		mirror://gentoo/${PN}-gentoo-init.gz"

HOMEPAGE="http://linux-wlan.org"
DEPEND="sys-kernel/linux-headers
		dev-libs/openssl
		sys-apps/baselayout
		>=sys-apps/sed-4.0*"

SLOT="0"
LICENSE="MPL-1.1"
KEYWORDS="x86"

# Note: To use this ebuild, you should have the usr/src/linux symlink to
# the kernel directory that linux-wlan-ng should use for configuration.
#
# linux-wlan-ng requires a configured pcmcia-cs source tree.
# unpack/configure it in WORKDIR.  No need to compile it though.

src_unpack() {
	check_KV

	okvminor="${KV#*.}" ; okvminor="${okvminor%%.*}"
	if [ "${okvminor}" -gt 4 ]; then
		eerror "This version of linux-wlan-ng will NOT work with 2.6 kernels"
		eerror "Please use linux-wlan-ng-0.2.1_pre17 for 2.6 kernels."
		eerror "For now, you will need to disable sandbox to get this to merge."
		eerror "See bug #32737 for info on work being done to fix this."
		die "This version of linux-wlan-ng does not support 2.6 kernels"
	fi

	unpack ${P}.tar.gz
	unpack ${PN}-gentoo-init.gz

	# Use pcmcia.eclass to figure out what to do about pcmcia
	pcmcia_src_unpack

	# install a gentoo style init script
	cp ${WORKDIR}/${PN}-gentoo-init ${S}/etc/rc.wlan

	# Lots of sedding to do to get the man pages and a few other
	# things to end up in the right place.

	cd ${S}
	#mv man/Makefile man/Makefile.orig
	sed -i -e "s:mkdir:#mkdir:" \
		-e "s:cp nwepgen.man:#cp nwepgen.man:" \
		-e "s:\t\$(TARGET_:\t#\$(TARGET_:" \
			man/Makefile

	#mv etc/wlan/Makefile etc/wlan/Makefile.orig
	sed -i -e "s:/etc/wlan:/etc/conf.d:g" \
		etc/wlan/Makefile

	#mv etc/wlan/wlancfg-DEFAULT etc/wlan/wlancfg-DEFAULT.orig
	sed -i -e "s:/sbin/nwepgen:/sbin/keygen:" \
		etc/wlan/wlancfg-DEFAULT

	#mv etc/wlan/shared etc/wlan/shared.orig
	sed -i -e "s:/etc/wlan/wlan.conf:/etc/conf.d/wlan.conf:g" \
	    -e "s:/etc/wlan/wlancfg:/etc/conf.d/wlancfg:g" \
		etc/wlan/shared

}

src_compile() {
	# Configure the pcmcia-cs sources if we actually are going to use them
	pcmcia_configure

	# now lets build wlan-ng
	cd ${S}

	#cp config.in default.config

	sed -i -e 's:TARGET_ROOT_ON_HOST=:TARGET_ROOT_ON_HOST=${D}:' \
		-e 's:PRISM2_PCI=n:PRISM2_PCI=y:' \
			config.in
	#mv default.config config.in

	if use pcmcia; then
		if [ -n "${PCMCIA_SOURCE_DIR}" ]
		then
			export PCMCIA_SOURCE_DIR=${PCMCIA_SOURCE_DIR}
			sed -i -e 's:PCMCIA_SRC=:PCMCIA_SRC=${PCMCIA_SOURCE_DIR}:' \
				config.in
		fi
		sed -i -e 's:PRISM2_PLX=n:PRISM2_PLX=y:' \
			config.in
	else
		sed -i -e 's:PRISM2_PCMCIA=y:PRISM2_PCMCIA=n:' \
			config.in
	fi
	#mv default.config config.in

	if use usb; then
		sed -i -e 's:PRISM2_USB=n:PRISM2_USB=y:' \
			config.in
		#mv default.config config.in
	fi

	#mv default.config config.in
	cp config.in default.config

	emake default_config || die "failed configuring WLAN"
	emake all || die "failed compiling"

	# compile add-on keygen program.  It seems to actually provide usable keys.
	cd ${S}/add-ons/keygen

	emake || die "Failed to compile add-on keygen program"
}

src_install () {

	make install || die "failed installing"

	dodir etc/wlan
	mv ${D}/etc/conf.d/shared ${D}/etc/wlan/

	if ! use build; then

		dodir /usr/share/man/man1
		newman ${S}/man/nwepgen.man nwepgen.1
		newman ${S}/man/wlancfg.man wlancfg.1
		newman ${S}/man/wlanctl-ng.man wlanctl-ng.1
		newman ${S}/man/wland.man wland.1

		dodoc CHANGES COPYING LICENSE FAQ README THANKS TODO \
		      doc/config* doc/capturefrm.txt
	fi

	exeinto /sbin
	doexe add-ons/keygen/keygen

}

pkg_postinst() {
	depmod -a

	einfo "Setup:"
	einfo ""
	einfo "/etc/init.d/wlan is used to control startup and shutdown of non-PCMCIA devices."
	einfo "/etc/init.d/pcmcia from pcmcia-cs is used to control startup and shutdown of"
	einfo "PCMCIA devices."
	einfo ""
	einfo "The wlan-ng.opts file in /etc/pcmcia/ is now depricated."
	einfo ""
	einfo "Modify /etc/conf.d/wlan.conf to set global parameters."
	einfo "Modify /etc/conf.d/wlancfg-* to set individual card parameters."
	einfo "There are detailed instructions in these config files."
	einfo ""
	einfo "Be sure to add iface_wlan0 parameters to /etc/conf.d/net."
	einfo ""
	ewarn "Wireless cards which you want to use drivers other than wlan-ng for"
	ewarn "need to have the appropriate line removed from /etc/pcmcia/wlan-ng.conf"
	ewarn "Do 'cardctl info' to see the manufacturer ID and remove the corresponding"
	ewarn "line from that file."
}
