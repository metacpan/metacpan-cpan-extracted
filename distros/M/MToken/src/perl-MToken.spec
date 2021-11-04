# General defines
%define shortnname mtoken
%define daemonname mtoken
%define username mtoken
%define groupname mtoken


Name:           perl-MToken
Version:        1.04
Release:        1%{?dist}
Summary:        MToken - Tokens processing system (Security)
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            https://metacpan.org/release/MToken
Source:         https://cpan.metacpan.org/authors/id/A/AB/ABALAMA/MToken-%{version}.tar.gz
BuildArch:      noarch

# Build
BuildRequires:  perl
BuildRequires:  perl(ExtUtils::MakeMaker)

# Pragmas
BuildRequires:  perl(base)
BuildRequires:  perl(constant)
BuildRequires:  perl(constant)
BuildRequires:  perl(feature)
BuildRequires:  perl(vars)

# Runtime
BuildRequires:  perl(Archive::Tar)
BuildRequires:  perl(CTK) >= 2.03
BuildRequires:  perl(DBI)
BuildRequires:  perl(DBD::SQLite)
BuildRequires:  perl(Digest::MD5)
BuildRequires:  perl(Digest::SHA)
BuildRequires:  perl(Encode::Locale)
BuildRequires:  perl(File::HomeDir)
BuildRequires:  perl(Mojolicious)
BuildRequires:  perl(Try::Tiny)
BuildRequires:  perl(URI)

# General
Requires:       perl(:MODULE_COMPAT_%(eval "$(perl -V:version)"; echo $version))
Requires:       openssl
Requires:       gnupg2
Requires:       perl(Archive::Tar)
Requires:       perl(CTK) >= 2.03
Requires:       perl(DBI)
Requires:       perl(DBD::SQLite)
Requires:       perl(Digest::MD5)
Requires:       perl(Digest::SHA)
Requires:       perl(Encode::Locale)
Requires:       perl(File::HomeDir)
Requires:       perl(Mojolicious)
Requires:       perl(Try::Tiny)
Requires:       perl(URI)


%{?perl_default_filter}


%description
Tokens processing system (Security)


%prep
%setup -q -n MToken-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
%{__make} %{?_smp_mflags}


%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
%{__make} install DESTDIR=%{buildroot}
find %{buildroot} -type f -name .packlist -exec rm -f {} ';'
find %{buildroot} -type f -name perllocal.pod -exec rm -f {} ';'
%{_fixperms} %{buildroot}/*

# Filesystem.
mkdir -p %{buildroot}%{_sysconfdir}
%{__cp} -R conf %{buildroot}%{_sysconfdir}/%{shortnname}
mkdir -p %{buildroot}%{_datadir}
%{__cp} -R src/www %{buildroot}%{_datadir}/%{shortnname}
mkdir -p %{buildroot}%{_sharedstatedir}/%{shortnname}
mkdir -p %{buildroot}%{_rundir}/%{shortnname}


# Install systemd unit files.
mkdir -p %{buildroot}%{_unitdir}
%{__install} -pDm644 src/%{daemonname}.service %{buildroot}%{_unitdir}/%{daemonname}.service
%{__install} -pDm644 src/%{daemonname}.default %{buildroot}%{_sysconfdir}/sysconfig/%{daemonname}


%check
%{__make} test


%pre
getent group %{groupname} &> /dev/null || groupadd -r %{groupname} &> /dev/null
getent passwd %{username} &> /dev/null || useradd -r -g %{groupname} -s /sbin/nologin %{username} &> /dev/null


%post
%systemd_post %{daemonname}.service


%preun
%systemd_preun %{daemonname}.service


%postun
%systemd_postun_with_restart %{daemonname}.service


%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc Changes README
%license LICENSE
%config(noreplace) %{_sysconfdir}/%{shortnname}
%{perl_vendorlib}/*
%{_bindir}/*
%{_mandir}/man1/*.1*
%{_mandir}/man3/*.3*
%{_datadir}/%{shortnname}/*
%{_unitdir}/%{daemonname}.service
%config(noreplace) %{_sysconfdir}/sysconfig/%{daemonname}
%dir %attr(0755, %{username}, %{groupname}) %{_sharedstatedir}/%{shortnname}


%changelog
* Sun Oct 10 2021 Serz Minus <abalama@cpan.org> - 1.04-1
- Mojolicious added
- Initial RHEL build

* Sat Jul 20 2019 Serz Minus <abalama@cpan.org> - 1.03-1
- Changed SHA1 digest module

* Wed Jun 19 2019 Serz Minus <abalama@cpan.org> - 1.02-1
- Initial RHEL build

* Mon Jun 3 2019 Serz Minus <abalama@cpan.org> - 1.01-1
- Initial release
