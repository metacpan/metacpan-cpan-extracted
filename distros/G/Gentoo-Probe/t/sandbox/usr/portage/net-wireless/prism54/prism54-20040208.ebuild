# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-wireless/prism54/prism54-20040208.ebuild,v 1.1 2004/06/20 09:09:36 linguist Exp $

MY_P=${P/prism54-/prism54-cvs}
DESCRIPTION="Driver for Intersil Prism GT / Prism Duette wireless chipsets"
HOMEPAGE="http://prism54.org/"

# nomirror for firmware issues. Emails sent to inquire about this.
RESTRICT="nomirror"
SRC_URI="mirror://gentoo/${MY_P}.tar.bz2
		http://prism54.org/~mcgrof/firmware/isl3890"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="pcmcia"

DEPEND="virtual/kernel"
RDEPEND=">=sys-apps/hotplug-20030805-r2
		net-wireless/wireless-tools
		pcmcia? ( sys-apps/pcmcia-cs )"

S=${WORKDIR}/${MY_P}

src_unpack() {
	check_KV

	einfo "Make sure you have CONFIG_FW_LOADER enabled in your kernel."
	einfo "2.6 users will need to disable sandbox for now to avoid"
	einfo "sandbox issues. See bug #32737 for info on work being done to"
	einfo "fix this."
	einfo "Module versioning (CONFIG_MODVERSION) should be disabled."

	unpack ${MY_P}.tar.bz2
}

src_compile() {
	unset ARCH
	make KVER=${KV} KDIR=/usr/src/linux modules || die
}

src_install() {
	make KDIR=/usr/src/linux KVER=${KV} \
		KMISC=${D}/lib/modules/${KV}/kernel/drivers/net/wireless/prism54/ \
		install || die

	# Install the firmware image
	insinto /usr/lib/hotplug/firmware/
	doins ${DISTDIR}/isl3890

	dodoc README ksrc/{TODO,ChangeLog}
}

pkg_postinst() {
	if [[ ${ROOT} = / ]]; then
		/sbin/depmod -a
	fi
}
