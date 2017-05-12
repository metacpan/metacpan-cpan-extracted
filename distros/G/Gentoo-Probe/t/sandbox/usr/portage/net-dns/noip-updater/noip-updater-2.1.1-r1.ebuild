# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/noip-updater/noip-updater-2.1.1-r1.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

inherit eutils

IUSE=""

MY_P=${P/-updater/}
S=${WORKDIR}/${MY_P}
DESCRIPTION="no-ip.com dynamic DNS updater"
HOMEPAGE="http://www.no-ip.com"
SRC_URI="http://www.no-ip.com/client/linux/${MY_P}.tar.gz"
PATCHES="${FILESDIR}/${MY_P}.patch"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="x86 ~ppc ~sparc alpha ~hppa ~mips ~amd64 ~ia64 ~ppc64"

RDEPEND="virtual/glibc"

DEPEND="${RDEPEND} sys-devel/gcc"

src_unpack() {
	unpack ${A}
	cd ${S}

	sed -i \
		-e "s:\(#define CONFIG_FILEPATH\).*:\1 \"/etc\":" \
		-e "s:\(#define CONFIG_FILENAME\).*:\1 \"/etc/no-ip2.conf\":" \
		noip2.c
}

src_compile() {
	emake \
		PREFIX=/usr \
		CONFDIR=/etc || die
}

src_install() {
	into /usr
	dosbin noip2
	dodoc README.FIRST COPYING
	exeinto /etc/init.d
	newexe ${FILESDIR}/noip2.start noip
	prepalldocs
}

pkg_postinst() {

	einfo "Configuration can be done manually via:"
	einfo "/usr/sbin/noip2 -C or "
	einfo "first time you use the /etc/init.d/noip script; or"
	einfo "by using this ebuild's config option."
	einfo
	einfo "You must update the /etc/init.d/noip script, the "
	einfo "binary name and the command line options have "
	einfo "changed."
}

pkg_config() {
	cd /tmp
	einfo "Answer the following questions."
	noip2 -C || die
}

