# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/bind/bind-9.2.2_rc1-r2.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

IUSE="ssl ipv6 doc"

MY_P=${P/_}
S=${WORKDIR}/${MY_P}
DESCRIPTION="BIND - Berkeley Internet Name Domain - Name Server"
SRC_URI="ftp://ftp.isc.org/isc/bind9/${PV/_}/${MY_P}.tar.gz"
HOMEPAGE="http://www.isc.org/products/BIND/bind9-beta.html"

KEYWORDS="x86 ppc sparc alpha"
LICENSE="as-is"
SLOT="0"

DEPEND="sys-apps/groff
	>=sys-apps/sed-4
	ssl? ( >=dev-libs/openssl-0.9.6g )"

RDEPEND="${DEPEND}
	selinux? ( sec-policy/selinux-bind )"

src_unpack() {
	unpack ${MY_P}.tar.gz && cd ${S}

	# Adjusting PATHs in manpages
	for i in `echo bin/{named/named.8,check/named-checkconf.8,nsupdate/nsupdate.8,rndc/rndc.8}`; do
	sed -i \
		-e 's:/etc/named.conf:/etc/bind/named.conf:g' \
		-e 's:/etc/rndc.conf:/etc/bind/rndc.conf:g' \
		-e 's:/etc/rndc.key:/etc/bind/rndc.key:g' ${i}
	done
}

src_compile() {
	local myconf=""

	use ssl && myconf="${myconf} --with-openssl"
	use ipv6 && myconf="${myconf} --enable-ipv6" || myconf="${myconf} --enable-ipv6=no"

	econf 	--sysconfdir=/etc/bind \
		--localstatedir=/var \
		--enable-threads \
		--with-libtool \
		${myconf} || die "econf failed"

	make || die "failed to compile bind"
}

src_install() {
	einstall

	dodoc CHANGES COPYRIGHT FAQ README

	use doc && {
	docinto misc ; dodoc doc/misc/*
	docinto html ; dodoc doc/arm/*
	docinto	draft ; dodoc doc/draft/*
	docinto rfc ; dodoc doc/rfc/*
	docinto contrib ; dodoc contrib/named-bootconf/named-bootconf.sh \
	contrib/nanny/nanny.pl
	}

	# some handy-dandy dynamic dns examples
	cd ${D}/usr/share/doc/${PF}
	tar pjxf ${FILESDIR}/dyndns-samples.tbz2

	dodir /etc/bind /var/bind/{pri,sec}

	insinto /etc/bind ; newins ${FILESDIR}/named.conf-r1 named.conf
	# ftp://ftp.rs.internic.net/domain/named.ca:
	insinto /var/bind ; doins ${FILESDIR}/named.ca
	insinto /var/bind/pri ; doins ${FILESDIR}/{127,localhost}

	exeinto /etc/init.d ; newexe ${FILESDIR}/named.rc6 named
	insinto /etc/conf.d ; newins ${FILESDIR}/named.confd named

	dosym ../../var/bind/named.ca /var/bind/root.cache
	dosym ../../var/bind/pri /etc/bind/pri
	dosym ../../var/bind/sec /etc/bind/sec
}

pkg_preinst() {
	# Let's get rid of those tools and their manpages since they're provided by bind-tools
	rm -f ${D}/usr/share/man/man1/{dig.1.gz,host.1.gz}
	rm -f ${D}/usr/bin/{dig,host,nslookup}
}

pkg_postinst() {
	if [ ! -f '/etc/bind/rndc.key' ]; then
		/usr/sbin/rndc-confgen -a -u named
	fi

	install -d -o named -g named ${ROOT}/var/run/named \
		${ROOT}/var/bind/pri ${ROOT}/var/bind/sec
	chown -R named:named ${ROOT}/var/bind

	echo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	echo
	einfo "The BIND ebuild now includes chroot support."
	einfo "If you like to run bind in chroot AND this is a new install OR"
	einfo "your bind doesn't already run in chroot, simply run:"
	einfo "\`ebuild /var/db/pkg/${CATEGORY}/${PF}/${PF}.ebuild config\`"
	einfo "Before running the above command you might want to change the chroot"
	einfo "dir in /etc/conf.d/named. Otherwise /chroot/dns will be used."
	echo
}

pkg_config() {

	CHROOT=`sed -n 's/^[[:blank:]]\?CHROOT="\([^"]\+\)"/\1/p' /etc/conf.d/named 2>/dev/null`

	if [ -z "$CHROOT" -a ! -d "/chroot/dns" ]; then
		CHROOT="/chroot/dns"
	elif [ -d ${CHROOT} ]; then
		eerror; eerror "${CHROOT:-/chroot/dns} already exists. Quitting."; eerror; EXISTS="yes"
	fi

	if [ ! "$EXISTS" = yes ]; then
		echo ; einfon "Setting up the chroot directory..."
		mkdir -m 700 -p ${CHROOT}
		mkdir -p ${CHROOT}/{dev,etc,var/run/named}
		chown -R named:named ${CHROOT}/var/run/named
		cp -R /etc/bind ${CHROOT}/etc/
		cp /etc/localtime ${CHROOT}/etc/localtime
		chown named:named ${CHROOT}/etc/bind/rndc.key
		cp -R /var/bind ${CHROOT}/var/
		chown -R named:named ${CHROOT}/var/
		mknod ${CHROOT}/dev/zero c 1 5
		mknod ${CHROOT}/dev/random c 1 8
		chmod 666 ${CHROOT}/dev/{random,zero}
		chown named:named ${CHROOT}

		grep -q "^#[[:blank:]]\?CHROOT" /etc/conf.d/named ; RETVAL=$?
		if [ $RETVAL = 0 ]; then
			sed 's/^# \?\(CHROOT.*\)$/\1/' /etc/conf.d/named > /etc/conf.d/named.orig 2>/dev/null
			mv --force /etc/conf.d/named.orig /etc/conf.d/named
		fi

		sleep 1; echo " Done."; sleep 1
		echo
		einfo "Add the following to your root .bashrc or .bash_profile: "
		einfo "   alias rndc='rndc -k ${CHROOT}/etc/bind/rndc.key'"
		einfo "Then do the following: "
		einfo "   source /root/.bashrc or .bash_profile"
		echo
	fi
}
