# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/app-shells/bash-completion/bash-completion-20040526-r2.ebuild,v 1.1 2004/06/20 09:09:34 linguist Exp $

GENCOMP_VERS="1.0_beta"

DESCRIPTION="Programmable Completion for bash (includes emerge and ebuild commands)."
HOMEPAGE="http://www.caliban.org/bash/index.shtml#completion"
SRC_URI="http://www.caliban.org/files/bash/${P}.tar.bz2
	mirror://sourceforge/gentoo-bashcomp/gentoo-bashcomp-${GENCOMP_VERS}.tar.gz"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="~x86 ~ppc ~sparc ~alpha ~mips ~hppa ~amd64 ~s390"

S=${WORKDIR}/${PN/-/_}

DEPEND="app-arch/tar
	app-arch/bzip2"

RDEPEND=">=app-shells/bash-2.05a"

src_install() {
	insinto /etc
	doins bash_completion

	insinto /usr/share/bash-completion
	doins contrib/*

	insinto /etc/profile.d
	doins ${FILESDIR}/bash-completion
	fperms 755 /etc/profile.d/bash-completion

	dodoc Changelog README

	cd ${WORKDIR}/gentoo-bashcomp-${GENCOMP_VERS}
	insinto /etc/bash_completion.d
	doins src/gentoo

	docinto gentoo
	dodoc AUTHORS NEWS TODO
}

pkg_postinst() {
	echo
	einfo "Add the following line to your ~/.bashrc to"
	einfo "activate completion support in your bash:"
	einfo "[ -f /etc/profile.d/bash-completion ] && source /etc/profile.d/bash-completion"
	einfo
	einfo "Additional complete functions can be enabled by symlinking them from"
	einfo "/usr/share/bash-completion to /etc/bash_completion.d"

	if [ -f /etc/bash_completion.d/gentoo.completion ]
	then
		echo
		ewarn "The file 'gentoo.completion' in '/etc/bash_completion.d/' has been"
		ewarn "replaced with 'gentoo'. Remove gentoo.completion to avoid problems."
	fi

	local bcfile moved
	for bcfile in /etc/bash_completion.d/{unrar,harbour,isql,larch,lilypond,p4,ri}
	do

		[ -f "${bcfile}" -a ! -L "${bcfile}" ] && moved="${bcfile##*/} ${moved}"
	done

	if [ -n "${moved}" ]
	then
		echo
		ewarn "The contrib files: ${moved}"
		ewarn "have been moved to /usr/share/bash-completion. Please DELETE"
		ewarn "those old files in /etc/bash_completion.d and create symlinks."
	fi
	echo
}
