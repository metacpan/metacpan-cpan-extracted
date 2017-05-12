# Copyright 1999-2004 Gentoo Technologies, Inc.
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/perl/Gentoo-Probe/t/sandbox/usr/portage/net-dns/bind/bind-9.2.3.ebuild,v 1.1 2004/06/20 09:09:35 linguist Exp $

IUSE="ssl ipv6 doc"

DESCRIPTION="BIND - Berkeley Internet Name Domain - Name Server"
SRC_URI="ftp://ftp.isc.org/isc/bind9/${PV}/${P}.tar.gz"
HOMEPAGE="http://www.isc.org/products/BIND/bind9.html"

KEYWORDS="-x86 -ppc -sparc -alpha -hppa -amd64 -ia64"
LICENSE="as-is"
SLOT="0"

DEPEND="sys-apps/groff
	>=sys-apps/sed-4
	ssl? ( >=dev-libs/openssl-0.9.6e )"

RDEPEND="${DEPEND}
	selinux? ( sec-policy/selinux-bind )"

src_unpack() {
	unpack ${A} && cd ${S}

	# Adjusting PATHs in manpages
	for i in `echo bin/{named/named.8,check/named-checkconf.8,nsupdate/nsupdate.8,rndc/rndc.8}`; do
		sed -i -e 's:/etc/named.conf:/etc/bind/named.conf:g' \
		       -e 's:/etc/rndc.conf:/etc/bind/rndc.conf:g' \
		       -e 's:/etc/rndc.key:/etc/bind/rndc.key:g' \
		       ${i}
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
		--enable-libbind \
		${myconf} || die "configure failed"

	MAKEOPTS="${MAKEOPTS} -j1" emake || die "failed to compile bind"
}

src_install() {
	make install DESTDIR=${D} || die "failed to install bind"

	dodoc CHANGES COPYRIGHT FAQ README

	use doc && {
		docinto misc ; dodoc doc/misc/*
		docinto html ; dodoc doc/arm/*
		docinto	draft ; dodoc doc/draft/*
		docinto rfc ; dodoc doc/rfc/*
		docinto contrib ; dodoc contrib/named-bootconf/named-bootconf.sh \
		contrib/nanny/nanny.pl
	}

	insinto /etc/env.d
	newins ${FILESDIR}/10bind.env 10bind

	# some handy-dandy dynamic dns examples
	cd ${D}/usr/share/doc/${PF}
	tar pjxf ${FILESDIR}/dyndns-samples.tbz2

	dodir /etc/bind /var/bind/{pri,sec}
	keepdir /var/bind/sec

	insinto /etc/bind ; newins ${FILESDIR}/named.conf-r2 named.conf
	# ftp://ftp.rs.internic.net/domain/named.ca:
	insinto /var/bind ; doins ${FILESDIR}/named.ca
	insinto /var/bind/pri ; doins ${FILESDIR}/{127,localhost}.zone

	exeinto /etc/init.d ; newexe ${FILESDIR}/named.rc6 named
	insinto /etc/conf.d ; newins ${FILESDIR}/named.confd named

	dosym ../../var/bind/named.ca /var/bind/root.cache
	dosym ../../var/bind/pri /etc/bind/pri
	dosym ../../var/bind/sec /etc/bind/sec

	# Fix lib dependancy craziness (Bug #32214)
	cd ${D}/usr/lib
	dosym libisc.so.7 /usr/lib/libisc.so.4
	dosym libdns.so.11.0.2 /usr/lib/libdns.so.10
	dosym libdns.so.11.0.2 /usr/lib/libdns.so.8
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

	einfo "The default zone files are now installed as *.zone,"
	einfo "be careful merging config files if you have modified"
	einfo "/var/bind/pri/127 or /var/bind/pri/localhost"
	einfo
	einfo "You can edit /etc/conf.d/named to customize named settings"
	einfo
	einfo "The BIND ebuild now includes chroot support."
	einfo "If you like to run bind in chroot AND this is a new install OR"
	einfo "your bind doesn't already run in chroot, simply run:"
	einfo "\`ebuild /var/db/pkg/${CATEGORY}/${PF}/${PF}.ebuild config\`"
	einfo "Before running the above command you might want to change the chroot"
	einfo "dir in /etc/conf.d/named. Otherwise /chroot/dns will be used."
	echo
	einfo "Recently verisign added a wildcard A record to the .COM and .NET TLD"
	einfo "zones making all .com and .net domains appear to be registered"
	einfo "This causes many problems such as breaking important anti-spam checks"
	einfo "which verify source domains exist. ISC released a patch for BIND which"
	einfo "adds 'delegation-only' zones to allow admins to return the .com and .net"
	einfo "domain resolution to their normal function."
	echo
	einfo "There is no need to create a com or net data file. Just the"
	einfo "entries to the named.conf file is enough."
	echo
	einfo "	zone "com" IN { type delegation-only; };"
	einfo "	zone "net" IN { type delegation-only; };"
}

pkg_config() {

	CHROOT=`sed -n 's/^[[:blank:]]\?CHROOT="\([^"]\+\)"/\1/p' /etc/conf.d/named 2>/dev/null`
	EXISTS="no"

	if [ -z "${CHROOT}" -a ! -d "/chroot/dns" ]; then
		CHROOT="/chroot/dns"
	elif [ -d ${CHROOT} ]; then
		eerror; eerror "${CHROOT:-/chroot/dns} already exists. Quitting."; eerror; EXISTS="yes"
	fi

	if [ ! "$EXISTS" = yes ]; then
		einfo ; einfon "Setting up the chroot directory..."
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
		einfo
		einfo "Add the following to your root .bashrc or .bash_profile: "
		einfo "   alias rndc='rndc -k ${CHROOT}/etc/bind/rndc.key'"
		einfo "Then do the following: "
		einfo "   source /root/.bashrc or .bash_profile"
		einfo
	fi
}

