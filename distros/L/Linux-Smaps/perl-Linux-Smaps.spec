Name:         perl-Linux-Smaps
License:      Artistic License
Group:        Development/Libraries/Perl
Provides:     p_Linux_Smaps
Obsoletes:    p_Linux_Smaps
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Linux::Smaps
Version:      0.08
Release:      1
Source:       Linux-Smaps-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Linux::Smaps

Authors:
--------
    Torsten Foertsch <torsten.foertsch@gmx.net>

%prep
%setup -n Linux-Smaps-%{version}
# ---------------------------------------------------------------------------

%build
perl Makefile.PL
make && make test
# ---------------------------------------------------------------------------

%install
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;
make DESTDIR=$RPM_BUILD_ROOT install_vendor
%{_gzipbin} -9 $RPM_BUILD_ROOT%{_mandir}/man3/Linux::Smaps.3pm || true
%perl_process_packlist

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && [ -d $RPM_BUILD_ROOT ] && rm -rf $RPM_BUILD_ROOT;

%files
%defattr(-, root, root)
%{perl_vendorlib}/Linux
%{perl_vendorarch}/auto/Linux
%doc %{_mandir}/man3/Linux::Smaps.3pm.gz
/var/adm/perl-modules/perl-Linux-Smaps
%doc MANIFEST README
