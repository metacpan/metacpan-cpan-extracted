Name:         perl-Math-EMA
License:      Artistic License
Group:        Development/Libraries/Perl
Requires:     perl = %{perl_version}
Autoreqprov:  on
Summary:      Math::EMA
Version:      0.02
Release:      1
Source:       Math-EMA-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-%{version}-build

%description
Math::EMA - implements the exponential moving average

Authors:
--------
    Torsten Förtsch <torsten.foertsch@gmx.net>

%prep
%setup -n Math-EMA-%{version}
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
%{perl_vendorlib}/Math
%{perl_vendorarch}/auto/Math
%doc %{_mandir}/man3
/var/adm/perl-modules/%{name}
%doc MANIFEST
