Name:           perl-Geo-Inverse
Version:        0.09
Release:        1%{?dist}
Summary:        Calculate geographic distance from a lat & lon pair
License:        perl
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Geo-Inverse/
Source0:        http://www.cpan.org/modules/by-module/Geo/Geo-Inverse-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Geo::Constants) >= 0.04
BuildRequires:  perl(Geo::Ellipsoids) >= 0.09
BuildRequires:  perl(Geo::Functions) >= 0.03
BuildRequires:  perl(Package::New)
BuildRequires:  perl(Test::Simple) >= 0.44
BuildRequires:  perl(Test::Number::Delta)
Requires:       perl(Geo::Constants) >= 0.04
Requires:       perl(Geo::Ellipsoids) >= 0.09
Requires:       perl(Geo::Functions) >= 0.03
Requires:       perl(Package::New)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This module is a pure Perl port of the NGS program in the public domain
"inverse" by Robert (Sid) Safford and Stephen J. Frakes.

%prep
%setup -q -n Geo-Inverse-%{version}

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
