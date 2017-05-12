Name:         perl-IO-Handle-Record
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      IO::Handle::Record
Version:      0.14
Release:      1
Source:       IO-Handle-Record-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
IO::Handle::Record

Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n IO-Handle-Record-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/IO::Handle::Record.3pm || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorarch}/IO
%{perl_vendorarch}/auto/IO
%doc %{_mandir}/man3/IO::Handle::Record.3pm.gz
/var/adm/perl-modules/perl-IO-Handle-Record
%doc MANIFEST
