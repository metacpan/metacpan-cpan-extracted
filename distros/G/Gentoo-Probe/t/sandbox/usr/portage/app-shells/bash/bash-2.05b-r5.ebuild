# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/bash/bash-2.05b-r5.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit eutils flag-o-matic

# Official patches
PLEVEL="x002 x003 x004"

DESCRIPTION="The standard GNU Bourne again shell"
SRC_URI="mirror://gnu/bash/${P}.tar.gz
	mirror://gentoo/${P}-gentoo.diff.bz2
	${PLEVEL//x/mirror://gnu/bash/bash-${PV}-patches/bash${PV/\.}-}"
HOMEPAGE="http://www.gnu.org/software/bash/bash.html"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="amd64 x86 ppc sparc ~alpha mips hppa"
IUSE="nls build"

DEPEND=">=sys-libs/ncurses-5.2-r2"

src_unpack() {
	unpack ${P}.tar.gz

	cd ${S}
	epatch ${DISTDIR}/${P}-gentoo.diff.bz2

	for x in ${PLEVEL//x}
	do
		epatch ${DISTDIR}/${PN}${PV/\.}-${x}
	done

	# Remove autoconf dependency
	cp Makefile.in Makefile.in.orig
	sed -e "/&& autoconf/d" Makefile.in.orig > Makefile.in

	# Readline is slow with multibyte locale, bug #19762
	epatch ${FILESDIR}/${P}-multibyte-locale.patch
	# Segfault on empty herestring
	epatch ${FILESDIR}/${P}-empty-herestring.patch
}

src_compile() {

	filter-flags -malign-double

	local myconf=""

	# Always use the buildin readline, else if we update readline
	# bash gets borked as readline is usually not binary compadible
	# between minor versions.
	#
	# Martin Schlemmer <azarah@gentoo.org> (1 Sep 2002)
	#use readline && myconf="--with-installed-readline"
	#use static && export LDFLAGS="${LDFLAGS} -static"
	use nls || myconf="${myconf} --disable-nls"

	econf \
		--disable-profiling \
		--with-curses \
		--without-gnu-malloc \
		${myconf} || die

	make || die
}

src_install() {
	einstall || die

	dodir /bin
	mv ${D}/usr/bin/bash ${D}/bin
	dosym bash /bin/sh

	use build \
		&& rm -rf ${D}/usr \
		|| ( \
			doman doc/*.1
			dodoc README NEWS AUTHORS CHANGES COMPAT COPYING Y2K
			dodoc doc/FAQ doc/INTRO

			ebegin "creating info symlink"
			dosym bash.info.gz /usr/share/info/bashref.info.gz
			eend $?
	)
}
