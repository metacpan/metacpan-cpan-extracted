Summary: Log Handler
Name: perl-Log-Handler
Version: 0.90
Release: 1%{dist}
License: GPL+ or Artistic
Group: Development/Libraries
Distribution: RHEL and CentOS

Packager: Jonny Schulz <js@bloonix.de>
Vendor: Bloonix

BuildArch: noarch
BuildRoot: %{_tmppath}/Log-Handler-%{version}-%{release}-root

Source0: http://search.cpan.org/CPAN/authors/id/B/BL/BLOONIX/Log-Handler-%{version}.tar.gz
Provides: perl(Log::Handler)
Requires: perl(Params::Validate)
AutoReqProv: no

%description
Log::Handler is an easy-to-use Perl module for logging, debugging, and tracing.

%prep
%setup -q -n Log-Handler-%{version}

%build
%{__perl} Build.PL installdirs=vendor
%{__perl} Build

%install
%{__perl} Build install destdir=%{buildroot} create_packlist=0
find %{buildroot} -name .packlist -exec %{__rm} {} \;
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
%{_fixperms} %{buildroot}/*

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%doc ChangeLog INSTALL LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Fri Oct 24 2014 Jonny Schulz <js@bloonix.de> - 0.84-1
- Fixed some version conflicts.
* Thu Oct 23 2014 Jonny Schulz <js@bloonix.de> - 0.83-1
- Added method set_default_param.
* Mon Aug 25 2014 Jonny Schulz <js@bloonix.de> - 0.82-1
- Initial self-created RPM release.
