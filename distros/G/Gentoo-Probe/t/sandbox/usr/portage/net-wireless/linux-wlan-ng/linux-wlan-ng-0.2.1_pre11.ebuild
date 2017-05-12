# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/linux-wlan-ng/linux-wlan-ng-0.2.1_pre11.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $


inherit eutils

IUSE="apm build nocardbus pcmcia pnp trusted usb"

PCMCIA_CS="pcmcia-cs-3.2.1"
PATCH_3_2_2="pcmcia-cs-3.2.1-3.2.2.diff.gz"
PATCH_3_2_3="pcmcia-cs-3.2.1-3.2.3.diff.gz"
PATCH_3_2_4="pcmcia-cs-3.2.1-3.2.4.diff.gz"
PCMCIA_DIR="${WORKDIR}/${PCMCIA_CS}"
MY_P=${PN}-${PV/_/-}
S=${WORKDIR}/${MY_P}

DESCRIPTION="The linux-wlan Project"
SRC_URI="ftp://ftp.linux-wlan.org/pub/linux-wlan-ng/${MY_P}.tar.gz
		mirror://gentoo/${PN}-gentoo-init.gz
		pcmcia?	( mirror://sourceforge/pcmcia-cs/${PCMCIA_CS}.tar.gz )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_2} )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_3} )
		pcmcia? ( mirror://gentoo/${PATCH_3_2_4} )"

HOMEPAGE="http://linux-wlan.org"
DEPEND="sys-kernel/linux-headers
		dev-libs/openssl
		sys-apps/baselayout
		pcmcia?	( sys-apps/pcmcia-cs )"
SLOT="0"
LICENSE="MPL-1.1"
KEYWORDS="~x86"

# check arch for configure
if [ ${ARCH} = "x86" ] ; then
	MY_ARCH="i386"
else
	MY_ARCH="ppc"
fi

# Note: To use this ebuild, you should have the usr/src/linux symlink to
# the kernel directory that linux-wlan-ng should use for configuration.
#
# linux-wlan-ng requires a configured pcmcia-cs source tree.
# unpack/configure it in WORKDIR.  No need to compile it though.

src_unpack() {

	unpack ${MY_P}.tar.gz
	unpack ${PN}-gentoo-init.gz
	cp ${WORKDIR}/${PN}-gentoo-init ${S}/etc/rc.wlan

	if use pcmcia; then
		unpack ${PCMCIA_CS}.tar.gz
		cd ${PCMCIA_DIR}
		if [ -z "`has_version =sys-apps/pcmcia-cs-3.2.4*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_4}
		elif [ -z "`has_version =sys-apps/pcmcia-cs-3.2.3*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_3}
		elif [ -z "`has_version =sys-apps/pcmcia-cs-3.2.2*`" ]; then
			epatch ${DISTDIR}/${PATCH_3_2_2}
		fi
	fi


	# Lots of sedding to do to get the man pages and a few other
	# things to end up in the right place.

	cd ${S}
	mv man/Makefile man/Makefile.orig
	sed -e "s:mkdir:#mkdir:" \
		-e "s:cp nwepgen.man:#cp nwepgen.man:" \
		-e "s:\t\$(TARGET_:\t#\$(TARGET_:" \
		man/Makefile.orig > man/Makefile

	mv etc/wlan/Makefile etc/wlan/Makefile.orig
	sed -e "s:/etc/wlan:/etc/conf.d:g" \
		etc/wlan/Makefile.orig > etc/wlan/Makefile

	mv etc/wlan/wlancfg-DEFAULT etc/wlan/wlancfg-DEFAULT.orig
	sed -e "s:/sbin/nwepgen:/sbin/keygen:" \
		etc/wlan/wlancfg-DEFAULT.orig > etc/wlan/wlancfg-DEFAULT

	mv etc/wlan/shared etc/wlan/shared.orig
	sed -e "s:/etc/wlan/wlan.conf:/etc/conf.d/wlan.conf:g" \
	    -e "s:/etc/wlan/wlancfg:/etc/conf.d/wlancfg:g" \
		etc/wlan/shared.orig > etc/wlan/shared

}

src_compile() {

	#
	# configure pcmcia-cs - we need this for wlan to compile
	# use same USE flags that the pcmcia-cs ebuild does.
	# no need to actually compile pcmcia-cs...
	# * This is actually only used if pcmcia_cs is NOT compiled into
	# the kernel tree.
	#

	if use pcmcia; then
		cd ${WORKDIR}/${PCMCIA_CS}
		local myconf
		if use trusted ; then
			myconf="--trust"
		else
			myconf="--notrust"
		fi

		if use apm ; then
			myconf="$myconf --apm"
		else
			myconf="$myconf --noapm"
		fi

		if use pnp ; then
			myconf="$myconf --pnp"
		else
			myconf="$myconf --nopnp"
		fi

		if use nocardbus ; then
			myconf="$myconf --nocardbus"
		else
			myconf="$myconf --cardbus"
		fi

		#use $CFLAGS for user tools, but standard kernel optimizations for
		#the kernel modules (for compatibility)
		./Configure -n \
			--target=${D} \
			--srctree \
			--kernel=/usr/src/linux \
			--arch="${MY_ARCH}" \
			--uflags="${CFLAGS}" \
			--kflags="-Wall -Wstrict-prototypes -O2 -fomit-frame-pointer" \
			$myconf || die "failed configuring pcmcia-cs"
	fi
	# now lets build wlan-ng
	cd ${S}

	sed -e 's:TARGET_ROOT_ON_HOST=:TARGET_ROOT_ON_HOST=${D}:' \
		-e 's:PRISM2_PCI=n:PRISM2_PCI=y:' \
		config.in > default.config
	mv default.config config.in

	if use pcmcia; then
		export PCMCIA_CS=${PCMCIA_CS}
		sed -e 's:PCMCIA_SRC=:PCMCIA_SRC=${WORKDIR}/${PCMCIA_CS}:' \
			-e 's:PRISM2_PLX=n:PRISM2_PLX=y:' \
			config.in > default.config
	else
		sed -e 's:PRISM2_PCMCIA=y:PRISM2_PCMCIA=n:' \
		config.in > default.config
	fi
	mv default.config config.in

	if use usb; then
		sed -e 's:PRISM2_USB=n:PRISM2_USB=y:' \
			config.in > default.config
		mv default.config config.in
	fi

	mv default.config config.in
	cp config.in default.config

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

	einfo "Configuration of the WLAN package has changed since 0.1.16-pre4."
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
	einfo "Three keygen programs are included: nwepgen, keygen, and lwepgen."
	einfo "keygen seems provide more usable keys at the moment."
	einfo ""
	einfo "Be sure to add iface_wlan0 parameters to /etc/conf.d/net."
	einfo ""
	ewarn "Wireless cards which you want to use drivers other than wlan-ng for"
	ewarn "need to have the appropriate line removed from /etc/pcmcia/wlan-ng.conf"
	ewarn "Do 'cardctl info' to see the manufacturer ID and remove the corresponding"
	ewarn "line from that file."
}


