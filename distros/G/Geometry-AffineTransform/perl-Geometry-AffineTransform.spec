%define modname Geometry-AffineTransform
Version: 1.4
Release: 1
Name: perl-%{modname}
Requires: perl >= 0:5.00503
Summary: %{modname} Perl module
License: distributable
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-root
BuildArch: noarch
BuildRequires: perl >= 0:5.00503
Source0: %{modname}-%{version}.tar.gz


%description

Geometry::AffineTransform - Perl module to map 2D coordinates to other 2D coordinates

%prep
%setup -q -n %{modname}-%{version} 

%build
CFLAGS="$RPM_OPT_FLAGS" perl Makefile.PL PREFIX=$RPM_BUILD_ROOT/usr
make


%clean
rm -rf $RPM_BUILD_ROOT
%install

rm -rf $RPM_BUILD_ROOT
eval `perl '-V:installarchlib'`
mkdir -p $RPM_BUILD_ROOT/$installarchlib
make install

find $RPM_BUILD_ROOT -name '.packlist' -exec rm -f {} \;
find $RPM_BUILD_ROOT -name 'perllocal.pod' -exec rm -f {} \;

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find $RPM_BUILD_ROOT/usr -type f -print | \
	sed "s@^$RPM_BUILD_ROOT@@g" > %{name}-%{version}-filelist
if [ "$(cat %{name}-%{version}-filelist)X" = "X" ] ; then
	echo "ERROR: EMPTY FILE LIST"
	exit -1
fi

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)

%changelog
* Wed Aug 20 2008 Marc Liyanage <reg.cpan@entropy.ch> 1.0-1
- initial version
