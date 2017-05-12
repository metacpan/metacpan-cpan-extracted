# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/linux-wlan-ng/linux-wlan-ng-0.2.1_pre19.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit pcmcia eutils

IUSE="${IUSE} usb build"

MY_P=${PN}-${PV/_/-}
S=${WORKDIR}/${MY_P}

DESCRIPTION="The linux-wlan Project"
SRC_URI="${SRC_URI}
		ftp://ftp.linux-wlan.org/pub/linux-wlan-ng/${MY_P}.tar.gz
		mirror://gentoo/${PN}-gentoo-init.gz"

HOMEPAGE="http://linux-wlan.org"
DEPEND="sys-kernel/linux-headers
		dev-libs/openssl
		>=sys-apps/sed-4.0*"

SLOT="0"
LICENSE="MPL-1.1"
KEYWORDS="~x86"

src_unpack() {
	check_KV

	unpack ${MY_P}.tar.gz
	unpack ${PN}-gentoo-init.gz

	# Use pcmcia.eclass to setup pcmcia-cs sources as needed
	pcmcia_src_unpack

	cp ${WORKDIR}/${PN}-gentoo-init ${S}/etc/rc.wlan

	# Small fix to make sure prism2dl compiles against /usr/include/linux
	# and not /usr/src/linux/include/linux. Userland shouldn't use
	# /usr/src/linux (especially this seems to break under 2.6 headers)

	cd ${S}
	EPATCH_SINGLE_MSG="Fixing prism2dl includes to use /usr/include/linux" \
		epatch ${FILESDIR}/${P}-prism2dl.diff

	# Lots of sedding to do to get the man pages and a few other
	# things to end up in the right place.

	sed -i -e "s:mkdir:#mkdir:" \
		-e "s:cp nwepgen.man:#cp nwepgen.man:" \
		-e "s:\t\$(TARGET_:\t#\$(TARGET_:" \
		man/Makefile

	sed -i -e "s:/etc/wlan:/etc/conf.d:g" \
		etc/wlan/Makefile

	sed -i -e "s:/sbin/nwepgen:/sbin/keygen:" \
		etc/wlan/wlancfg-DEFAULT

	sed -i -e "s:/etc/wlan/wlan.conf:/etc/conf.d/wlan.conf:g" \
	    -e "s:/etc/wlan/wlancfg:/etc/conf.d/wlancfg:g" \
		etc/wlan/shared

}

src_compile() {
	# Configure the pcmcia-cs tree if it exists
	pcmcia_configure

	# now lets build wlan-ng
	cd ${S}

	sed -i -e 's:TARGET_ROOT_ON_HOST=:TARGET_ROOT_ON_HOST=${D}:' \
		-e 's:PRISM2_PCI=n:PRISM2_PCI=y:' \
		config.in

	if use pcmcia; then
		if [ -n "${PCMCIA_SOURCE_DIR}" ];
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

	if use usb; then
		sed -i -e 's:PRISM2_USB=n:PRISM2_USB=y:' \
			config.in
	fi

	cp config.in default.config

	# 2.6 needs ARCH unset since it uses it
	unset ARCH
	emake default_config || die "failed configuring WLAN"
	emake all || die "failed compiling"

	# compile add-on keygen program.  It seems to actually provide usable keys.
	cd ${S}/add-ons/keygen
	emake || die "Failed to compile add-on keygen program"
	cd ${S}/add-ons/lwepgen
	emake || die "Failed to compile add-on lwepgen program"
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
	doexe add-ons/lwepgen/lwepgen

}

pkg_postinst() {
	depmod -a

	einfo "/etc/init.d/wlan is used to control startup and shutdown of non-PCMCIA devices."
	einfo "/etc/init.d/pcmcia from pcmcia-cs is used to control startup and shutdown of"
	einfo "PCMCIA devices."
	einfo ""
	einfo "Modify /etc/conf.d/wlan.conf to set global parameters."
	einfo "Modify /etc/conf.d/wlancfg-* to set individual card parameters."
	einfo "There are detailed instructions in these config files."
	einfo ""
	einfo "Three keygen programs are included: nwepgen, keygen, and lwepgen."
	einfo "keygen seems provide more usable keys at the moment."
	einfo ""
	einfo "Be sure to add iface_wlan0 parameters to /etc/conf.d/net."
	einfo ""
	ewarn "Wireless cards which you want to use drivers other than wlan-ng for"
	ewarn "need to have the appropriate line removed from /etc/pcmcia/wlan-ng.conf"
	ewarn "Do 'cardctl info' to see the manufacturer ID and remove the corresponding"
	ewarn "line from that file."

	ewarn "Previous versions of linux-wlan-ng recommended creating symlinks in"
	ewarn "/usr/src/linux for 2.6 kernel merges. This is NOT needed and will"
	ewarn "merely clutter things. This has been fixed in the ebuild where it"
	ewarn "should be handled."
	ewarn "Users emerging this with a 2.6 kernel still need to disable"
	ewarn "sandbox and userpriv from FEATURES."
}


