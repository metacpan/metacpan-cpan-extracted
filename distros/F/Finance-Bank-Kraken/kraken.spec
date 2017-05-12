# $Id: kraken.spec 73 2014-06-02 11:25:54Z phil $

%define rname Finance-Bank-Kraken
Name: perl-%{rname}
Version: 0.3
Release: 1%{?dist}
Summary: an api.kraken.com connector module
License: LGPL
Group: Development/Libraries
URL: http://search.cpan.org/dist/%{rname}/
Source0: http://search.cpan.org/CPAN/authors/id/P/PH/PHILIPPE/%{rname}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
Requires: perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires: perl(HTTP::Request)
Requires: perl(LWP::UserAgent)
Requires: perl(MIME::Base64)
Requires: perl(Digest::SHA)
BuildRequires: perl(ExtUtils::MakeMaker) perl(Module::Build) perl(Test::Simple)


%description
This module allows to connect to the api of the bitcoin market Kraken.

Please see https://www.kraken.com/help/api for a catalog of api methods.


%prep
%setup -q -n %{rname}-%{version}


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}
make pure_install PERL_INSTALL_ROOT=%{buildroot}

find %{buildroot} -type f -name .packlist -delete
find %{buildroot} -depth -type d -empty -delete

%{_fixperms} %{buildroot}/*


%clean
[ '%{buildroot}' != '/' ] && rm -rf %{buildroot}


%files
%defattr(-,root,root,-)
%doc README
%{perl_vendorlib}/Finance/Bank/Kraken.pm
%{_mandir}/man3/Finance::Bank::Kraken.3pm*
