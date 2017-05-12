# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# Header: $

S="${WORKDIR}/${P}-src"

DESCRIPTION="Toolkit for Internationalized Domain Names (IDN)"
HOMEPAGE="http://www.nic.ad.jp/ja/idn/idnkit/download/"
SRC_URI="http://www.nic.ad.jp/ja/idn/idnkit/download/sources/${P}-src.tar.gz"
LICENSE="JNIC"
SLOT="0"
KEYWORDS="x86 ~ppc"
IUSE=""
DEPEND="libidn"

src_install()
{
	einstall || die
	dodoc Changelog DISTFILES INSTALL INSTALL.ja LICENSE.txt NEWS \
		README README.ja

}
