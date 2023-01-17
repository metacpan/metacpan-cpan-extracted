Name:           perl-ExtUtils-MakeMaker-META_MERGE-GitHub
Version:        0.04
Release:        2%{?dist}
Summary:        Perl package to generate ExtUtils::MakeMaker META_MERGE for GitHub repositories
License:        MIT
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/ExtUtils-MakeMaker-META_MERGE-GitHub/
Source0:        http://www.cpan.org/modules/by-module/ExtUtils/ExtUtils-MakeMaker-META_MERGE-GitHub-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple)
#requires for script perl-ExtUtils-MakeMaker-META_MERGE-GitHub.pl
Requires:       git
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Generates the META_MERGE key and hash value for a normal GitHub repository.

%prep
%setup -q -n ExtUtils-MakeMaker-META_MERGE-GitHub-%{version}

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
%doc Changes README.md
%{perl_vendorlib}/*
%{_mandir}/man3/*
%{_mandir}/man1/*
%{_bindir}/*

%changelog
