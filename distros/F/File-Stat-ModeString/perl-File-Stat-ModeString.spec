%define       class File
%define    subclass Stat
%define subsubclass ModeString
%define     version 1.00
%define     release 1

# Derived values
%define real_name %{class}-%{subclass}-%{subsubclass}
%define name perl-%{real_name}

Summary: 	Perl module for conversion file stat(2) mode to/from string representation
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
Requires: 	perl >= 5.5.0, perl-File-Stat-Bits >= 0.12
#Conflicts:	%{name} < %{version}

BuildRoot: 	%{_tmppath}/%{name}-buildroot/
BuildRequires:	perl >= 5.5.0

# '(not relocateable)' if absent
Prefix:		/usr


%description
This module provides a few functions for conversion between
binary and literal representations of file mode bits,
including file type.

All of them use only symbolic constants for mode bits
from File::Stat::Bits.


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

