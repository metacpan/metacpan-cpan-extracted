Name: <% $zilla->name %>
Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
Release: 1%{?dist}
Summary: <% $zilla->abstract %>
License: GPL+ or Artistic
Group: Development/Libraries
BuildArch: noarch
URL: https://www.labmeasurement.de/
Source: <% $archive %>
BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
## this isn't a 'package' so auto-provides doesn't work on it
Provides: perl(Lab::XPRESS::Utilities::Utilities)


%global __requires_exclude ^perl\\((Lab::Zhinst|USB::TMC|LinuxGpib|Lab::VISA|Lab::VXI11))
%{?perl_default_filter}

# make the hardware interface modules non-required, but
# (if possible) 'Recommends'/Suggested, otherwise 
# package has problems being installed unless the full
# suite of interfaces is used.

# not all distros have 'recommends', but rpm >= 4.12.0 added it
# this is a bit of trickery to check version of rpm and compare to 4.12.0
%if %(printf '%s\n%s\n' `rpm -q rpm --qf %{V}` "4.12.0"| sort -VC ; echo $?)
Recommends:  perl(Lab::Zhinst)
Recommends:  perl(USB::TMC)
Recommends:  perl(LinuxGpib)
Recommends:  perl(Lab::VISA)
Recommends:  perl(Lab::VXI11)
%endif


%description
<% $zilla->abstract %>

%prep
%setup -q

%build
perl Makefile.PL
make test

%install
if [ "%{buildroot}" != "/" ] ; then
rm -rf %{buildroot}
fi
make install DESTDIR=%{buildroot}
find %{buildroot} -type f | sed -e 's#%{buildroot}##' > %{_tmppath}/filelist

install -d %{buildroot}/etc/udev
install utilities/udev-rules/usbtmc_protfix %{buildroot}/etc/udev
install -d %{buildroot}/etc/udev/rules.d
install utilities/udev-rules/70-usbtmc.rules %{buildroot}/etc/udev/rules.d

%clean
if [ "%{buildroot}" != "/" ] ; then
rm -rf %{buildroot}
fi

%files -f %{_tmppath}/filelist
%defattr(-,root,root)
%config /etc/udev/rules.d/70-usbtmc.rules
%attr(0755,root,root) /etc/udev/usbtmc_protfix
%config /etc/udev/usbtmc_protfix
%doc README HACKING COPYING Changes COPYING.Artistic COPYING.GPL-2

%post
### using default group 'daq' for usbtmc stuff, so make sure
### it exists. Should alter the /etc/udev/...usbtmc.. stuff too
### if you're using a different group for this
grinfo=`getent group daq`
if [ "x$grinfo" == "x" ] ; then
   echo "creating group 'daq'"
   groupadd -r daq
fi
