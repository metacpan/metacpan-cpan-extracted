Name:           perl-Geo-H3
Version:        0.06
Release:        1%{?dist}
Summary:        H3 Geospatial Hexagon Indexing System
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Geo-H3/
Source0:        http://www.cpan.org/modules/by-module/Geo/Geo-H3-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Geo::H3::FFI)
BuildRequires:  perl(Test::More)
BuildRequires:  perl(Test::Number::Delta)
Requires:       perl(Geo::H3::FFI)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Perl API to the H3 Geospatial Hexagon Indexing System C library using
libffi and FFI::Platypus.

%prep
%setup -q -n Geo-H3-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes META.json README
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_mandir}/man1/*
%{_bindir}/*

%changelog
