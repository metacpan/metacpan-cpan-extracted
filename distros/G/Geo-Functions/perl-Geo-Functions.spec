Name:           perl-Geo-Functions
Version:        0.08
Release:        1%{?dist}
Summary:        Package for standard Geo:: functions
License:        CHECK(Distributable)
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Geo-Functions/
Source0:        http://www.cpan.org/modules/by-module/Geo/Geo-Functions-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Exporter)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Geo::Constants) >= 0.06
Requires:       perl(Exporter)
Requires:       perl(Geo::Constants) >= 0.06
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Package for standard Geo:: functions.

%prep
%setup -q -n Geo-Functions-%{version}

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
%doc Changes LICENSE README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
