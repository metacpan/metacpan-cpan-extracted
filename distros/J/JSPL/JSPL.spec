%define pmod_ver 1.04

Summary: Perl JSPL module, a bridge between Spidermonkey javascript engine and perl
Name: perl-JSPL
Version: %{pmod_ver}
Release: 1
License: Artistic
Group: Applications/CPAN
URL: http://search.cpan.org/search?mode=module&query=JSPL
Source0: JSPL-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildRequires: perl
BuildRequires: xulrunner-devel
Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
The perl JSPL module is a bridge between Mozilla's SpiderMonkey JavaScript
engine and Perl engine.

It allows you to execute JavaScript code inside a perl script and extend the
JavaScript land with perl functions, classes, even entire namespaces,
automatically reflecting every object, variable, function, etc...

Included is a perl extendible JavaScript shell for run full-blow js applications.

%prep
%setup -n JSPL-%{version}

%build
%{__perl} Makefile.PL \
	INSTALLDIRS=vendor \
	OPTIMIZE="$RPM_OPT_FLAGS"

%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type f -name '*.bs' -a -size 0 -exec rm -f {} ';'
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null ';'
[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress
chmod -R u+w $RPM_BUILD_ROOT/*
find $RPM_BUILD_ROOT -type f -print | \
        sed "s@^$RPM_BUILD_ROOT@@g" > "%{name}-%{version}-%{release}-filelist"
if [ ! -s "%{name}-%{version}-%{release}-filelist" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit -1
fi

%clean
%{__rm} -rf %{buildroot}

%files -f "%{name}-%{version}-%{release}-filelist"
%defattr(-, root, root, 0755)

%changelog
* Sat Jun 12 2010 Salvador Ortiz <sog@msg.com.mx> 1.01
- For v1.01
