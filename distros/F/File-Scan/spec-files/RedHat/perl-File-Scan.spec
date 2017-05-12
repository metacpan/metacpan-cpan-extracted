%define class File
%define subclass Scan
%define version 1.43
%define release 1

# Derived values
%define module %{class}-%{subclass}
%define perlver %(rpm -q perl --queryformat '%%{version}' 2>/dev/null)

Summary:	Perl module %{class}::%{subclass}
Name:		perl-%{module}
Version:	%{version}
Release:	%{release}
Group:		Development/Perl
License:	See documentation
Vendor:		Henrique Dias <hdias@aesbuc.pt>
Source:		http://www.cpan.org/modules/by-module/%{module}-%{version}.tar.gz
Url:		http://www.cpan.org/modules/by-module/%{class}
BuildRequires:	perl
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-root/
Requires:	perl = %{perlver}
Provides:	%{module} = %{version}

%description
Perl module which implements the %{class}::%{subclass} class. 

%prep
%setup -q -n %{module}-%{version}

%build
%{__perl} Makefile.PL
%{__make} OPTIMIZE="$RPM_OPT_FLAGS"

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall PREFIX=$RPM_BUILD_ROOT%{_prefix}

# Install the example scan program as virusscan
mkdir -p $RPM_BUILD_ROOT%{_bindir}
install -m 755 examples/scan.pl $RPM_BUILD_ROOT%{_bindir}/virusscan

# Clean up some files we don't want/need
rm -rf `find $RPM_BUILD_ROOT -name "perllocal.pod" -o \
		-name ".packlist" -o \
		-name "*.bs"`

# Remove all empty directories
find $RPM_BUILD_ROOT%{_prefix} -type d | tac | xargs rmdir --ign

%clean
HERE=`pwd`
cd ..
rm -rf $HERE
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc Changes README TODO docs/write_sign_bin.txt
%{_prefix}

%changelog
* Wed May 04 2005 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.43
* Mon Mar 07 2005 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.42
* Sat Feb 19 2005 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.41
* Sat Feb 12 2005 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.40
* Tue Dec 21 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.39
* Mon Nov 22 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.38
* Sat Nov 06 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.37
* Sat Oct 30 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.36
* Mon Oct 18 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.35
* Fri Oct 15 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.34
* Tue Oct 12 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.33
* Thu Oct 07 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.32
* Wed Oct 06 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.31
* Sat Sep 18 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.30
* Wed Sep 15 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.29
* Sat Sep 11 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.28
* Tue Aug 17 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.27
* Tue Jul 27 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.26
* Wed Jul 21 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.25
* Wed Jul 21 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.24
* Sat Jul 17 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.23
* Sat Jul 10 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.22
* Tue Jul 06 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.21
* Sat Jul 03 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.20
* Mon Jun 28 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.19
* Sat Jun 19 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.18
* Mon Jun 14 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.17
* Sat Jun 12 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.16
* Sat May 29 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.15
* Sat May 22 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.14
* Wed May 19 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.13
* Mon May 17 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.12
* Fri May 07 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.11
* Wed May 05 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.10
* Mon May 03 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.09
* Fri Apr 30 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.08
* Wed Apr 28 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.07
* Wed Apr 28 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.06
* Tue Apr 27 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.05
* Mon Apr 26 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.04
* Thu Apr 22 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.03
* Wed Apr 14 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.02
* Mon Apr 05 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.01
* Fri Apr 02 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 1.00
* Fri Mar 26 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.99
* Tue Mar 23 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.98
* Mon Mar 22 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.97
* Fri Mar 19 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.96
* Thu Mar 18 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.95
* Thu Mar 11 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.94
* Tue Mar 09 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.93
* Mon Mar 08 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.92
* Wed Mar 03 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.91
* Wed Mar 03 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.90
* Tue Mar 02 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.89
* Mon Mar 01 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.88
* Sun Feb 29 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.87
* Thu Feb 26 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.86
* Wed Feb 25 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.85
* Wed Feb 18 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.84
* Tue Feb 17 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.83
* Fri Feb 10 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.82
* Fri Jan 30 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.81
* Tue Jan 27 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.80
* Mon Jan 19 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.79
* Tue Jan 06 2004 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.78
* Mon Dec 22 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.77
* Fri Nov 28 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.76
* Wed Nov 19 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.75
* Sat Nov 15 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.74
* Tue Nov 04 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.73
* Tue Nov 04 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.72
* Mon Nov 03 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.71
* Mon Nov 03 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.70
* Fri Oct 10 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.69
* Tue Sep 30 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.68
* Mon Sep 29 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.67
* Fri Sep 19 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.66
* Tue Sep 09 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.65
* Tue Sep 02 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.64
* Tue Aug 19 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.63
* Mon Aug 09 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.62
* Mon Aug 04 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.61
* Mon Jul 28 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.60
* Mon Jul 01 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.59
* Fri Jun 26 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.58
* Fri Jun 20 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.57
* Thu Jun 05 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.56
* Mon Jun 02 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.55
* Tue May 20 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.54
* Fri May 16 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.53
* Wed May 14 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.52
* Sat Apr 26 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.51
* Wed Apr 23 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.50
* Tue Apr 22 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.49
* Fri Apr 11 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.48
* Wed Apr 09 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.47
* Tue Apr 08 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.46
* Sat Mar 29 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.45
* Sat Mar 15 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.44
* Mon Jan 13 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.43
* Fri Jan 10 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.42
* Thu Jan 09 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.41
* Sat Jan 04 2003 Henrique Dias <hdias@aesbuc.pt>
- Updated to 0.40
* Sat Dec 28 2002 Henrique Dias <hdias@esb.ucp.pt>
- Updated to 0.39
* Tue Nov 12 2002 Henrique Dias <hdias@esb.ucp.pt>
- Updated to 0.38
* Fri Oct 02 2002 Henrique Dias <hdias@esb.ucp.pt>
- Updated to 0.37
* Thu Sep 12 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.36
* Fri Aug 30 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.35
* Mon Jul 22 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.34
* Tue Jul 15 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.33
* Tue Jul 08 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.32
* Tue Jun 25 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.31
* Tue Jun 17 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.30
* Mon Jun 03 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.29
* Mon May 27 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.28
* Sat May 20 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.27
* Mon May 14 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.26
  Inserted code to adapt to perl version
  Replaced real_name macro with module
* Sun May 05 2002 Michael McLagan <michael.mclagan@linux.org>
- Updated to 0.25
  Fixed a couple of items in spec file
* Tue Apr 30 2002 Michael McLagan <michael.mclagan@linux.org>
- initial version 0.24
