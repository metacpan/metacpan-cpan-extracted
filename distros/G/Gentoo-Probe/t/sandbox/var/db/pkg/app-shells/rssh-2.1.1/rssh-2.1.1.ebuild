# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/var/db/pkg/app-shells/rssh-2.1.1/rssh-2.1.1.ebuild,v 1.1 2004/06/20 09:09:37 linguist Exp $

DESCRIPTION="Restricted shell for SSHd."
HOMEPAGE="http://rssh.sourceforge.net/"
SRC_URI="mirror://sourceforge/rssh/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="x86 ppc sparc"
IUSE="static"

RDEPEND="virtual/ssh"

src_compile() {
	econf \
		--libexecdir=/usr/lib/misc \
		--with-scp=/usr/bin/scp \
		--with-sftp-server=/usr/lib/misc/sftp-server \
		`use_enable static` || die "econf failed"
	emake || die
}

src_install() {
	einstall libexecdir="${D}/usr/lib/misc"
	dodoc AUTHORS ChangeLog CHROOT INSTALL README TODO
}
