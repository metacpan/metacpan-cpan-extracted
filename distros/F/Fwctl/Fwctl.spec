Summary: Program to control the firewall with high level syntax
Name: Fwctl
Version: 0.28
Release: 1i
Source: http://iNDev.iNsu.COM/sources/%{name}-%{version}.tar.gz
Copyright: GPL
Group: Applications/System
Prefix: /usr
URL: http://iNDev.iNsu.COM/Fwctl/
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArchitectures: noarch
Prereq: /sbin/chkconfig

%description
Fwctl is a module to configure the Linux kernel packet filtering firewall
using higher level abstraction than rules on input, output and forward
chains. It supports masquerading and accounting as well. There is also
a powerful report generation utility.

%prep
%setup -q
%fix_perl_path

%build
perl Makefile.PL 
make OPTIMIZE="$RPM_OPT_FLAGS" MAN1EXT=8
#make test

%install
rm -fr $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make 	PREFIX=$RPM_BUILD_ROOT/usr \
	MAN1EXT=8 \
	INSTALLBIN=$RPM_BUILD_ROOT/usr/sbin \
	INSTALLSCRIPT=$RPM_BUILD_ROOT/usr/sbin \
	INSTALLMAN1DIR=$RPM_BUILD_ROOT/usr/man/man8 \
   	INSTALLMAN3DIR=$RPM_BUILD_ROOT/`dirname $installarchlib`/man/man3 \
   	pure_install

# Fix packing list
for packlist in `find $RPM_BUILD_ROOT -name '.packlist'`; do
	mv $packlist $packlist.old
	sed -e "s|$RPM_BUILD_ROOT||g" < $packlist.old > $packlist
	rm -f $packlist.old
done

BuildDirList > %pkg_file_list
BuildFileList >> %pkg_file_list

umask 007
mkdir -p $RPM_BUILD_ROOT/{usr/sbin,etc/{fwctl,cron.d,rc.d/init.d,logrotate.d}}
install -m 750 fwctl.init $RPM_BUILD_ROOT/etc/rc.d/init.d/fwctl
install -m 640 fwctl.cron $RPM_BUILD_ROOT/etc/cron.d/fwctl
install -m 640 fwctl.logrotate $RPM_BUILD_ROOT/etc/logrotate.d/fwctl
install -m 640 etc/* $RPM_BUILD_ROOT/etc/fwctl

mkdir -p $RPM_BUILD_ROOT/var/log
touch $RPM_BUILD_ROOT/var/log/{fwctl_acct,fwctl_log}
chmod 640 $RPM_BUILD_ROOT/var/log/*

%post 
if [ "$1" = 1 ]; then
	chkconfig --add fwctl
fi

%preun 
if [ "$1" = 0 ]; then
	chkconfig --del fwctl
fi

%clean
rm -fr $RPM_BUILD_ROOT

%files -f %{name}-file-list
%defattr(-,root,root)
%doc README ChangeLog TODO NEWS THANKS
%config /etc/rc.d/init.d/fwctl
%dir /etc/fwctl
%config(missingok) /etc/logrotate.d/fwctl
%config(noreplace) /etc/fwctl/aliases
%config(noreplace) /etc/fwctl/interfaces
%config(noreplace) /etc/fwctl/rules
%config /etc/cron.d/fwctl
%config(noreplace) %attr(640,root,root) /var/log/fwctl_*

%changelog
* Tue Aug 01 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.28-1i]
- Updated to version 0.28.
- Updated spec file to use new macros.

* Sun Jun 11 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.27-1i]
- Updated to version 0.27.

* Mon May 08 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.26-1i]
- Released 0.26.

* Thu Feb 17 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.25-3i]
- Moved weekly reports back to logrotate script.

* Wed Feb 16 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.25-2i]
- Moved weekly report to cron.d/fwctl.

* Fri Feb 11 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.25-1i]
- Updated to version 0.25.

* Wed Jan 26 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.24-1i]
- Updated to version 0.24.

* Sun Jan 23 2000  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.23-1i]
- Updated to version 0.23.
- Added empty fwctl_acct and fwctl_log files with empty size but
  proper permissions.
- Cron script became a crontab file.
- Update of the file list.

* Wed Dec 15 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.22-1i]
- Updated to version 0.22.
- Updated list of Provides and Requires.

* Tue Oct 19 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.21-1i]
- Updated to version 0.21.

* Wed Sep 15 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.20-1i]
- Updated to version 0.20.

* Fri Sep 03 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.18-1i]
- Updated to version 0.18.

* Mon Aug 23 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.16-1i]
- Fixed botched release.
 
* Mon Aug 23 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
- Updated to version 0.15.
- Added requirements for Network-IPv4Addr.

* Thu Aug 19 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
- Updated to version 0.14.
- Put in man page.

* Mon Jul 05 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.13-1i]
- Updated to version 0.13.

* Mon Jul 05 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.12-1i]
- Updated to version 0.12.

* Mon Jul 05 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.11-1i]
- Updated to version 0.11.

* Sat May 29 1999  Francis J. Lacoste <francis.lacoste@iNsu.COM> 
  [0.10-1i]
- First RPM release.

