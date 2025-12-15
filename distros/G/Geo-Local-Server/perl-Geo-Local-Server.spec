Name:           perl-Geo-Local-Server
Version:        0.10
Release:        1%{?dist}
Summary:        Returns the configured coordinates of the local server
License:        BSD
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Geo-Local-Server/
Source0:        http://www.cpan.org/modules/by-module/Geo/Geo-Local-Server-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Config::IniFiles)
BuildRequires:  perl(Package::New)
BuildRequires:  perl(Path::Class)
BuildRequires:  perl(Test::Simple) >= 0.44
Requires:       perl(Config::IniFiles)
Requires:       perl(Package::New)
Requires:       perl(Path::Class)
Requires:       perl(DateTime)
Requires:       perl(DateTime::Event::Sunrise)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Reads coordinates from either the user environment variable
COORDINATES_WGS84_LON_LAT_HAE or the file /etc/local.coordinates.

%package profile
summary:        Returns the configured coordinates of the local server
Requires:       setup

%description profile
Installs a profile.d file to export the environment variable from
the /etc/local.coordinates file.

%prep
%setup -q -n Geo-Local-Server-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/
cp etc/local.coordinates              $RPM_BUILD_ROOT/%{_sysconfdir}/local.coordinates

mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/profile.d/
cp etc/profile.d-local.coordinates.sh $RPM_BUILD_ROOT/%{_sysconfdir}/profile.d/local.coordinates.sh

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc LICENSE
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_mandir}/man1/*
%{_bindir}/*
%config(noreplace) %attr(0644,root,root) %{_sysconfdir}/local.coordinates

%files profile
%defattr(-,root,root,-)
%attr(0755,root,root) %{_sysconfdir}/profile.d/local.coordinates.sh

%changelog
* Sun Dec 14 2025 Michael R. Davis (mrdvt92@yahoo.com) 0.10-1
- Updated for GitHub release
