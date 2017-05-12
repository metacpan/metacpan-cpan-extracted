# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/zsh/zsh-4.2.0-r1.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

inherit eutils

MYDATE="20040204"
MY_P="${P/_pre/-pre-}"
DESCRIPTION="UNIX Shell similar to the Korn shell"
HOMEPAGE="http://www.zsh.org/"
SRC_URI="ftp://ftp.zsh.org/pub/${MY_P}.tar.bz2
	cjk? ( http://www.ono.org/software/dist/${P}-euc-0.2.patch.gz )
	doc? ( ftp://ftp.zsh.org/pub/${MY_P}-doc.tar.bz2 )"

LICENSE="ZSH"
SLOT="0"
KEYWORDS="~x86 ~ppc ~sparc ~alpha arm ~hppa ~amd64"
IUSE="maildir ncurses static doc pcre cap"

RDEPEND="pcre? ( >=dev-libs/libpcre-3.9 )
	cap? ( sys-libs/libcap )
	ncurses? ( >=sys-libs/ncurses-5.1 )"
DEPEND="sys-apps/groff
	>=sys-apps/sed-4
	${RDEPEND}"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${MY_P}.tar.bz2
	use doc && unpack ${MY_P}-doc.tar.bz2
	cd ${S}
	use cjk && epatch ${DISTDIR}/${P}-euc-0.2.patch.gz
	cd ${S}/Doc
	ln -sf . man1
	# fix zshall problem with soelim
	soelim zshall.1 > zshall.1.soelim
	mv zshall.1.soelim zshall.1
}

src_compile() {
	local myconf

	use static && myconf="${myconf} --disable-dynamic" \
		&& LDFLAGS="${LDFLAGS} -static"

	econf \
		--bindir=/bin \
		--libdir=/usr/lib \
		--enable-etcdir=/etc/zsh \
		--enable-zshenv=/etc/zsh/zshenv \
		--enable-zlogin=/etc/zsh/zlogin \
		--enable-zlogout=/etc/zsh/zlogout \
		--enable-zprofile=/etc/zsh/zprofile \
		--enable-zshrc=/etc/zsh/zshrc \
		--enable-fndir=/usr/share/zsh/${PV}/functions \
		--enable-site-fndir=/usr/share/zsh/site-functions \
		--enable-function-subdirs \
		--enable-ldflags="${LDFLAGS}" \
		`use_with ncurses curses-terminfo` \
		`use_enable maildir maildir-support` \
		`use_enable pcre` \
		`use_enable cap` \
		${myconf} || die "configure failed"

	if use static ; then
		# compile all modules statically, see Bug #27392
		sed -i -e "s/link=no/link=static/g" \
			-e "s/load=no/load=yes/g" \
			config.modules || die
	else
		# avoid linking to libs in /usr/lib, see Bug #27064
		sed -i -e "/LIBS/s%-lpcre%/usr/lib/libpcre.a%" \
			Makefile || die
	fi

	# emake still b0rks
	emake -j1 || die "make failed"
	#make check || die "make check failed"
}

src_install() {
	einstall \
		bindir=${D}/bin \
		libdir=${D}/usr/lib \
		fndir=${D}/usr/share/zsh/${PV}/functions \
		sitefndir=${D}/usr/share/zsh/site-functions \
		install.bin install.man install.modules \
		install.info install.fns || die "make install failed"

	insinto /etc/zsh
	doins ${FILESDIR}/zprofile

	keepdir /usr/share/zsh/site-functions
	insinto /usr/share/zsh/site-functions
	newins ${FILESDIR}/_portage-${MYDATE} _portage
	insinto /usr/share/zsh/${PV}/functions/Prompts
	doins ${FILESDIR}/prompt_gentoo_setup

	dodoc ChangeLog* META-FAQ README INSTALL LICENCE config.modules

	if use doc ; then
		dohtml Doc/*
		insinto /usr/share/doc/${PF}
		doins Doc/zsh{.dvi,_us.ps,_a4.ps}
	fi

	docinto StartupFiles
	dodoc StartupFiles/z*
}

pkg_preinst() {
	# Our zprofile file does the job of the old zshenv file
	# Move the old version into a zprofile script so the normal
	# etc-update process will handle any changes.
	if [ -f /etc/zsh/zshenv -a ! -f /etc/zsh/zprofile ]; then
		mv /etc/zsh/zshenv /etc/zsh/zprofile
	fi
}

pkg_postinst() {
	einfo
	einfo "If you want to enable Portage completion and Gentoo prompt,"
	einfo "add"
	einfo "	autoload -U compinit promptinit"
	einfo "	compinit"
	einfo "	promptinit; prompt gentoo"
	einfo "to your ~/.zshrc"
	einfo
	# see Bug 26776
	ewarn
	ewarn "If you are upgrading from zsh-4.0.x you may need to"
	ewarn "remove all your old ~/.zcompdump files in order to use"
	ewarn "completion.  For more info see zcompsys manpage."
	ewarn
}
