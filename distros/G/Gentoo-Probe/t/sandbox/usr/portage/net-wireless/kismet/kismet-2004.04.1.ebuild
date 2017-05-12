# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/kismet/kismet-2004.04.1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

MY_P=${P/\./-}
MY_P=${MY_P/./-R}
ETHEREAL_VERSION="0.10.3"
DESCRIPTION="Kismet is a 802.11b wireless network sniffer."
HOMEPAGE="http://www.kismetwireless.net/"
SRC_URI="http://www.kismetwireless.net/code/${MY_P}.tar.gz
	 ethereal? (http://www.ethereal.com/distribution/ethereal-${ETHEREAL_VERSION}.tar.bz2)"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="acpi gps ethereal"

DEPEND="gps? ( >=dev-libs/expat-1.95.4 dev-libs/gmp media-gfx/imagemagick )
	>=sys-devel/autoconf-2.58"
RDEPEND="net-wireless/wireless-tools"

S=${WORKDIR}/${MY_P}

src_compile() {
	local myconf

	# To have kismet build acpi support, you need to be running a kernel
	# with acpi enabled at the time of compiling

	myconf="`use_enable acpi`"
	use gps || myconf="${myconf} --disable-gps"

	if use ethereal; then
		myconf="${myconf} --with-ethereal=${WORKDIR}/ethereal-${ETHEREAL_VERSION}"

		cd ${WORKDIR}/ethereal-${ETHEREAL_VERSION}/wiretap
		econf || die
		emake || die
	fi

	cd ${S}
	./configure \
	    --prefix=/usr \
		--host=${CHOST} \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--datadir=/usr/share \
		--sysconfdir=/etc/kismet \
		--localstatedir=/var/lib \
		${myconf} || die "./configure failed"

	cd ${S}/conf
	cp -f kismet.conf kismet.conf.orig
	cp -f kismet_ui.conf kismet_ui.conf.orig
	sed -e "s:/usr/local:/usr:g; \
			s:=ap_manuf:=/etc/kismet/ap_manuf:g; \
			s:=client_manuf:=/etc/kismet/client_manuf:g" \
			kismet.conf.orig > kismet.conf
	sed -e "s:/usr/local:/usr:g" kismet_ui.conf.orig > kismet_ui.conf
	rm -f kismet.conf.orig kismet_ui.conf.orig

	cd ${S}
	make dep || die "make dep for kismet failed"
	emake || die "compile of kismet failed"
}

src_install () {
	dodir /etc/kismet
	dodir /usr/bin
	make prefix=${D}/usr \
		ETC=${D}/etc/kismet MAN=${D}/usr/share/man \
		SHARE=${D}/usr/share/${PN} install || die
	 use gps && cp ${S}/scripts/gpsmap* ${D}/usr/bin/
	 dodoc CHANGELOG FAQ README docs/*

	exeinto /etc/init.d
	newexe ${FILESDIR}/rc-script-3 kismet
	insinto /etc/conf.d
	newins ${FILESDIR}/rc-conf-3 kismet
}
