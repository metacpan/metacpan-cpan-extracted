%define perl_vendorbin %(perl -MConfig -e 'print $Config{vendorbin}')

Name:         perl-MMapDB
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version} perl-File-Map
BuildRequires: perl = %{perl_version} perl-File-Map
Autoreqprov:  on
Summary:      MMapDB
Version:      0.13
Release:      1
Source:       MMapDB-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
The MMapDB perl module implements something similar to a database. It provides
very fast and lockfree data lookups because the whole database is mmapped into
the address space of the process. But modifications are very expensive.

Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n MMapDB-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
find $RPM_BUILD_ROOT%{_mandir}/man* -type f -print0 |
  xargs -0i^ %{_gzipbin} -9 ^ || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorarch}
%{perl_vendorbin}
%doc %{_mandir}/man3
/var/adm/perl-modules/perl-MMapDB
%doc MANIFEST
