%define       class File
%define    subclass Stat
%define subsubclass Bits
%define     version 1.01
%define     release 1

# Derived values
%define real_name %{class}-%{subclass}-%{subsubclass}
%define name perl-%{real_name}

Summary: 	Perl module which provides portable stat(2) bit mask constants
Name: 		%{name}
Version: 	%{version}
Release: 	%{release}
Group: 		Development/Perl
License:        GPL
Source: 	http://www.cpan.org/modules/by-module/%{class}/%{real_name}-%{version}.tar.gz
Url: 		http://www.cpan.org/modules/by-module/%{class}/%{real_name}-%{version}.readme
#Distribution:	MustDie/2000
#Vendor:	DF-Soft
Packager:       Dmitry Fedorov <fedorov@cpan.org>

#Provides:	"virtual package"
Requires: 	perl >= 5.5.0
#Conflicts:	%{name} < %{version}

BuildRoot: 	%{_tmppath}/%{name}-buildroot/
BuildRequires:	perl >= 5.5.0

# '(not relocateable)' if absent
Prefix:		/usr


%description
Lots of Perl modules use the Unix file permissions and type bits directly
in binary form with risk of non-portability for some exotic bits.
Note that the POSIX module does not provides all needed constants
and I can't wait when the POSIX module will be updated.

This separate module provides file type/mode bit and more constants
from sys/stat.ph and sys/sysmacros.ph without pollution caller's namespace
by other unneeded symbols from these headers.
Most of these constants exported by this module are Constant Functions
(see L<perlsub>).


%prep
%setup -q -n %{real_name}-%{version}
#%patch


%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" "PREFIX=%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall
rm -rf %{buildroot}%{perl_archlib} %{buildroot}%{perl_vendorarch}/auto/*/*/.packlist

# Clean up some files we don't want/need
rm -rf `find $RPM_BUILD_ROOT -name "perllocal.pod"`
rm -rf `find $RPM_BUILD_ROOT -name ".packlist" -o -name "*.bs"`

# Remove all empty directories
for i in `find $RPM_BUILD_ROOT -type d | tac`; do
   if [ -d $i ]; then
      rmdir --ign -p $i
   fi
done


%clean
cd ..
rm -rf $RPM_BUILD_ROOT
rm -rf $RPM_BUILD_DIR/%{real_name}-%{version}


%files
%defattr(-,root,root)
#%doc CHANGES
%{_prefix}

