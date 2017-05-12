# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/kismet/kismet-2.6.2-r1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

DESCRIPTION="Kismet is a 802.11b wireless network sniffer."
HOMEPAGE="http://www.kismetwireless.net/"
SRC_URI="http://www.kismetwireless.net/code/${P}.tar.gz
	 http://www.ethereal.com/distribution/old-versions/ethereal-0.9.7.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="x86 ~sparc ppc"
IUSE="acpi ipv6 gps"
DEPEND="gps? ( >=dev-libs/expat-1.95.4 media-gfx/imagemagick )
		>=net-libs/libpcap-0.7.1-r1"
RDEPEND="net-wireless/wireless-tools"
S="${WORKDIR}/${P}"

src_compile() {
	local myconf

	myconf="--with-ethereal=${WORKDIR}/ethereal-0.9.7"
	use acpi && myconf="${myconf} --enable-acpi"
	use ipv6 && myconf="${myconf} --enable-ipv6"
	use gps || myconf="${myconf} --disable-gps"

	cd ${WORKDIR}/ethereal-0.9.7
	econf || die "econf failed"

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
	sed -e "s/\/usr\/local/\/usr/g; \
			s/=ap_manuf/=\/etc\/kismet\/ap_manuf/g; \
			s/=client_manuf/=\/etc\/kismet\/client_manuf/g" \
			kismet.conf.orig > kismet.conf
	sed -e "s/\/usr\/local/\/usr/g" kismet_ui.conf.orig > kismet_ui.conf
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
		SHARE=${D}/usr/share/${PN} install
	dodoc CHANGELOG FAQ README docs/*
}
