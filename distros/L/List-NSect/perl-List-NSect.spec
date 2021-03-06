Name:           perl-List-NSect
Version:        0.06
Release:        1%{?dist}
Summary:        To cut or divide a list into N equal parts
License:        Distributable, see LICENSE
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/List-NSect/
Source0:        http://www.cpan.org/modules/by-module/List/List-NSect-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(List::MoreUtils)
BuildRequires:  perl(Test::Simple) >= 0.44
Requires:       perl(List::MoreUtils)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
List::NSect is an Exporter that exports the function "nsect".

%prep
%setup -q -n List-NSect-%{version}

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
%doc Changes LICENSE README Todo
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Sun Jan 27 2013 Michael R. Davis (mdavis@stopllc.com) 0.01-1
- Specfile autogenerated by cpanspec 1.78.
