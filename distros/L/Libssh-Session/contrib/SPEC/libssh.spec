
Name:		libssh
Version:	0.9.0
Release:	1%{?dist}
Summary:	Library implementing the SSH2 protocol

Group:		System Environment/Libraries
License:	LGPLv2+
URL:		http://www.libssh.org/
Source0:	%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires: cmake
BuildRequires: openssl-devel
BuildRequires: zlib-devel

%description
libssh is a Free Software / Open Source project. 
The libssh library is distributed under LGPL license. 
The libssh project has nothing to do with "libssh2", 
which is a completly different and independant project.

%package devel
Summary: Header files, libraries and development documentation for %{name}.
Group: Development/Libraries
Requires: %{name} = %{version}-%{release}

%description devel
This package contains the header files, static libraries and development
documentation for %{name}. If you like to develop programs using %{name},
you will need to install %{name}-devel.

%prep
%setup

%build
mkdir build
cd build
%cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DLIB_SUFFIX=64 -DLIB_INSTALL_DIR=/usr/lib64 ..
%{__make}

%install
%{__rm} -rf %{buildroot}
cd build
%{__make} install DESTDIR="%{buildroot}"

### Clean up buildroot
%{__chmod} 0644 %{buildroot}/usr/include/libssh/*

%clean
%{__rm} -rf %{buildroot}

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%defattr(-, root, root, 0755)
%doc AUTHORS ChangeLog COPYING README
%{_libdir}/libssh.so.*

%files devel
%defattr(-, root, root, 0755)
%{_includedir}/libssh/
%{_libdir}/cmake
%{_libdir}/libssh.so
%{_libdir}/pkgconfig/
#exclude %{_libdir}/libssh.la
#exclude %{_libdir}/libssh_threads.la

