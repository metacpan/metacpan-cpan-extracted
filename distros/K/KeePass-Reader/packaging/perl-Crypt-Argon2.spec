%define cpan_name Crypt-Argon2

Name:           perl-Crypt-Argon2
Version:        0.011
Release:        1%{?dist}
Summary:        Perl interface to the Argon2 key derivation functions
Group:          Development/Libraries
License:        GPL or Artistic
URL:            https://metacpan.org/pod/Crypt::Argon2
Source0:        https://cpan.metacpan.org/authors/id/L/LE/LEONT/%{cpan_name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Module::Build)

%description
This module implements the Argon2 key derivation function, which is suitable to convert any password into a cryptographic key. This is most often used to for secure storage of passwords but can also be used to derive a encryption key from a password. It offers variable time and memory costs as well as output size.

%prep
%setup -q -n %{cpan_name}-%{version}

%build
%{__perl} Build.PL
%{__perl} Build

%install
rm -rf %{buildroot}
%{__perl} Build pure_install --destdir $RPM_BUILD_ROOT  --installdirs vendor
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
%{_fixperms} $RPM_BUILD_ROOT/*

%check
#make test

%clean
rm -rf %{buildroot}

%files
%defattr(-,root,root,-)
%{perl_vendorarch}
%{_mandir}/man3/*.3*

%changelog
