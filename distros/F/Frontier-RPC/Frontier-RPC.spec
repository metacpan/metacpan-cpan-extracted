Summary: Perl module for RPC over XML
Name: Frontier-RPC
Version: @VERSION@
Release: 1
Source: ftp://ftp.uu.net/vendor/bitsko/gdo/Frontier-RPC-@VERSION@.tar.gz
Copyright: distributable
Group: Networking/Utilities
URL: http://www.bitsko.slc.ut.us/
Packager: ken@bitsko.slc.ut.us (Ken MacLeod)
BuildRoot: /tmp/Frontier-RPC

#
# $Id: Frontier-RPC.spec,v 1.2 2000/06/01 15:32:06 kmacleod Exp $
#

%description
Frontier::RPC implements UserLand Software's XML RPC (Remote Procedure
Calls using Extensible Markup Language).  Frontier::RPC includes both
a client module for making requests to a server and a daemon module
for implementing servers.  Frontier::RPC uses RPC2 format messages.

%prep
%setup

perl Makefile.PL INSTALLDIRS=perl

%build

make

%install

make PREFIX="${RPM_ROOT_DIR}/usr" pure_install

DOCDIR="${RPM_ROOT_DIR}/usr/doc/Frontier-RPC-@VERSION@-1"
mkdir -p "$DOCDIR/examples"
for ii in README COPYING Changes test.pl examples/*; do
  cp $ii "$DOCDIR/$ii"
  chmod 644 "$DOCDIR/$ii"
done

%files

/usr/doc/Frontier-RPC-@VERSION@-1

/usr/lib/perl5/Frontier/Client.pm
/usr/lib/perl5/Frontier/Daemon.pm
/usr/lib/perl5/Frontier/RPC2.pm
/usr/lib/perl5/Apache/XMLRPC.pm
/usr/lib/perl5/man/man3/Frontier::Client.3
/usr/lib/perl5/man/man3/Frontier::Daemon.3
/usr/lib/perl5/man/man3/Frontier::RPC2.3
/usr/lib/perl5/man/man3/Apache::XMLRPC.3
