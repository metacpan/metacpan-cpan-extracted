# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/csh/csh-1.29-r3.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

inherit flag-o-matic eutils ccc

DESCRIPTION="Classic UNIX shell with C like syntax"
HOMEPAGE="http://www.netbsd.org/"
SRC_URI="mirror://gentoo/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="x86 alpha arm ~amd64 ia64"
IUSE="static doc"

DEPEND="sys-devel/pmake !app-shells/tcsh"
RDEPEND="virtual/glibc"

S=${WORKDIR}/src/bin/csh

src_unpack() {
	# unpack the source tarball
	unpack ${A}

	# hide some BSDisms, mostly my work, got some hints from the
	# debian project (they use an older OpenBSD csh, though).
	cd ${S}; epatch ${FILESDIR}/linux-vs-bsd.diff || die "patching failed."

	# print the existing input after displaying completion options.
	# patch contributed by splite <splite-gentoo@sigint.cs.purdue.edu>
	# #24290
	epatch ${FILESDIR}/retype-input.diff || die "patching failed."

	# copy some required files over, from NetBSD

	cd ${S}; cp ${WORKDIR}/printf.c \
				${WORKDIR}/vis.h \
				${WORKDIR}/vis.c \
				${FILESDIR}/dot.login \
				${FILESDIR}/dot.cshrc \
				${S}

	# this parses the output of the bash builtin `kill`
	# and creates an array of signal names for csh.

	einfo "Making a list of signal names..."

	local cnt=0

	printf "/* automatically generated during %s build */\n\n" ${PF} > ${S}/signames.h
	printf "const char *const sys_signame[NSIG + 3] = {\n" >> ${S}/signames.h
	printf "\t\"EXIT\",\t\n" >> ${S}/signames.h

	let cnt++

	for i in `kill -l`
	do
		let $((cnt++))%2 && continue
		einfo "	Adding ${i:3}..."
		printf "\t\"%s\",\n" ${i:3} >> ${S}/signames.h
	done

	printf "\t\"DEBUG\",\n\t\"ERR\",\n\t(char *)0x0\n};\n\n" >> ${S}/signames.h

	einfo "Making some final tweaks..."
	sed -i 's#sys/tty.h#linux/tty.h#g' ${S}/file.c
	sed -i 's!\(#include "proc.h"\)!\1\n#include "signames.h"\n!g' ${S}/proc.c
	sed -i 's#\(strpct.c time.c\)#\1 vis.c#g' ${S}/Makefile
	sed -i 's!#include "namespace.h"!!g' ${S}/vis.c
	sed -i 's#/usr/games/fortune#/usr/bin/fortune#g' ${S}/dot.login

}

src_compile() {

	einfo "Adding flags required for succesful compilation..."

	# this should be easier than maintaining a patch. 
	append-flags -Dlint -w -D__dead="" -D__LIBC12_SOURCE__ -DNODEV="-1"
	append-flags -DTTYHOG=1024 -DMAXPATHLEN=4096 -D_GNU_SOURCE
	append-flags -D_DIAGASSERT="assert"

	# maybe they dont warn on BSD, but on linux they are very noisy.
	export NOGCCERROR=1

	# if csh is a users preferred shell, they may want
	# a static binary to help on the event of fs emergency.
	use static && append-ldflags -static

	# pmake is a portage binary as well, so specify full path.
	# if yours isnt in /usr/bin, you can set PMAKE_PATH.
	einfo "Starting build..."
	${PMAKE_PATH:-/usr/bin/}pmake || die "compile failed."

	echo
	size csh
	echo

	# make the c shell guide
	use doc && {
		einfo "Making documentation..."
		cd ${S}/USD.doc
		${PMAKE_PATH:-/usr/bin/}pmake
	}
	cd ${S}

	einfo "Making empty configuration files.."
	printf "#\n# System-wide .cshrc file for csh(1).\n\n" >	csh.cshrc
	printf "#\n# System-wide .login file for csh(1).\n\n" > csh.login
	printf "if ( -f /etc/csh.env ) source /etc/csh.env\n" >> csh.login
	printf "#\n# System-wide .logout file for csh(1).\n\n" > csh.logout
}

src_install() {
	exeinto /bin
	doexe csh

	doman csh.1

	use doc && dodoc USD.doc/paper.ps
	dodoc dot.cshrc dot.login

	insinto /etc
	doins csh.cshrc csh.login csh.logout
}

pkg_postinst() {
	echo
	use doc && {
		einfo "An Introduction to the C shell by Bill Joy, a "
		einfo "postscript document included with this shell has"
		einfo "been installed in /usr/share/doc/${PF}, if you are new"
		einfo "to the C shell, you may find it interesting."
	} || {
		einfo "You didnt have the \`doc\` use flag set, the"
		einfo "postscript document \"An Introduction to the C"
		einfo "shell by Bill Joy\" was not installed."
	}
	echo
	einfo "Example login scripts have been installed in /usr/share/doc/${PF}."
	einfo "You can install a simple dot.cshrc like this:"
	einfo
	einfo "	% zcat /usr/share/doc/${PF}/dot.cshrc > ~/.cshrc"
	einfo "	% zcat /usr/share/doc/${PF}/dot.login > ~/.login"
	einfo
	einfo "And then edit to your liking."
	echo
}
