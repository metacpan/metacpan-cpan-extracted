# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/x11-libs/gtk+/gtk+-1.2.10-r10.ebuild,v 1.1 2004/09/11 05:21:25 rich Exp $

GNOME_TARBALL_SUFFIX="gz"
inherit gnome.org eutils libtool

DESCRIPTION="The GIMP Toolkit"
HOMEPAGE="http://www.gtk.org/"
SRC_URI="${SRC_URI}
	http://www.ibiblio.org/gentoo/distfiles/gtk+-1.2.10-r8-gentoo.diff.bz2"

LICENSE="LGPL-2.1"
SLOT="1"
KEYWORDS="x86 ppc sparc alpha hppa amd64 ia64 mips"
IUSE="nls debug"

DEPEND="virtual/x11
	=dev-libs/glib-1.2*
	nls? ( sys-devel/gettext
		dev-util/intltool )"

src_unpack() {
	unpack ${P}.tar.gz

	cd ${S}/..
	epatch ${DISTDIR}/gtk+-1.2.10-r8-gentoo.diff.bz2

	# locale fix by sbrabec@suse.cz
	cd ${S}
	epatch ${FILESDIR}/${PN}-1.2-locale_fix.patch
}

src_compile() {

	elibtoolize

	local myconf=
	use nls || myconf="${myconf} --disable-nls"

	if use debug
	then
		myconf="${myconf} --enable-debug=yes"
	else
		myconf="${myconf} --enable-debug=minimum"
	fi

	econf \
		--sysconfdir=/etc \
		--with-xinput=xfree \
		--with-x \
		${myconf} || die

	emake || die
}

src_install() {

	make install DESTDIR=${D} || die

	preplib /usr

	dodoc AUTHORS COPYING ChangeLog* HACKING
	dodoc NEWS* README* TODO
	docinto docs
	cd docs
	dodoc *.txt *.gif text/*
	dohtml -r html

	#install nice, clean-looking gtk+ style
	insinto /usr/share/themes/Gentoo/gtk
	doins ${FILESDIR}/gtkrc
}

pkg_postinst() {

	ewarn "Older versions added /etc/X11/gtk/gtkrc which changed settings for"
	ewarn "all themes it seems.  Please remove it manually as it will not due"
	ewarn "to /env protection."
	echo ""
	einfo "The old gtkrc is available through the new Gentoo gtk theme."

}
