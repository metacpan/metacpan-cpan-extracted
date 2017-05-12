# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/var/db/pkg/app-shells/sash-3.7/sash-3.7.ebuild,v 1.1 2004/06/20 09:09:38 linguist Exp $

inherit eutils flag-o-matic

DESCRIPTION="A small static UNIX Shell with readline support"
HOMEPAGE="http://www.canb.auug.org.au/~dbell/ http://dimavb.st.simbirsk.su/vlk/"
SRC_URI="http://www.canb.auug.org.au/~dbell/programs/${P}.tar.gz"

LICENSE="freedist"
SLOT="0"
KEYWORDS="~x86 ~ppc ~sparc ~mips ~alpha arm ~hppa amd64 ia64 ~ppc64 s390"
IUSE="readline"

DEPEND="virtual/glibc
	>=sys-libs/zlib-1.1.4
	readline? ( >=sys-libs/readline-4.1 >=sys-libs/ncurses-5.2 )"
RDEPEND=""

src_unpack() {
	unpack ${P}.tar.gz
	cd ${S}

	epatch ${FILESDIR}/sash-3.6-fix-includes.patch
	use readline && epatch ${FILESDIR}/sash-3.6-readline.patch

	# this indicates broken header files but don't know what to do
	# about it yet.  (03 Mar 2004 agriffis)
	use ia64 && append-flags -Du64=__u64 -Du32=__u32 -Ds64=__s64 -Ds32=__s32

	# use our CFLAGS in the Makefile
	sed -e "s:-O3:${CFLAGS}:" -i Makefile
}

src_compile() {
	make || die
}

src_install() {
	into /
	dobin sash || die
	doman sash.1
	dodoc README
}
