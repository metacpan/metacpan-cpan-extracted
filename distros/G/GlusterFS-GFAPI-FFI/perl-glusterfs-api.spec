%define perl_vendorlib    %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch   %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)
%global perl_package_name libgfapi-perl

Name:           perl-glusterfs-api
Summary:        Perl bindings for GlusterFS libgfapi
Version:        0.4
Release:        1%{?dist}
License:        GPLv2 or LGPLv3+
Group:          System Environment/Libraries
Vendor:         Gluster Community
URL:            https://github.com/gluster/libgfapi-perl
Source0:        %{perl_package_name}-%{version}.tar.gz

BuildArch:      noarch

Requires:       glusterfs-api >= 3.7.0
BuildRequires:  perl-ExtUtils-MakeMaker

%description
libgfapi is a library that allows applications to natively access GlusterFS
volumes. This package contains perl bindings to libgfapi.

%prep
%setup -q -n %{perl_package_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

# Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

# Remove manfiles (conflicts with perl package)
%{__rm} -rf %{buildroot}/%{_mandir}/man3

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-, root, root, -)
%doc Changes MAINTAINERS VERSION README.md

%if ( 0%{?rhel} > 6 )
%license COPYING-GPLV2 COPYING-LGPLV3
%else
%doc COPYING-GPLV2 COPYING-LGPLV3
%endif

%{perl_vendorlib}/GlusterFS/*

%changelog
* Fri Feb 09 2018 Ji-Hyeon Gim <potatogim@gluesys.com> - 0.3-1
- Introducing spec file.
