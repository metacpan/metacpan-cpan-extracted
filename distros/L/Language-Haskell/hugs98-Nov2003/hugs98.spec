# Requires %defines of `name', `version' and `release'.
# (`make rpm' takes care of these - you aren't expected to
# use this spec directly)

Summary:      Hugs - A Haskell Interpreter
Vendor:       Galois Connections, Inc.
Name:         %{name}
Version:      %{version}
Release:      %{release}
License:      BSDish
Group:        Development/Languages/Haskell
Packager:     jeff@galois.com
URL:          http://www.haskell.org/hugs
Source0:      %{name}-%{version}.tar.gz
BuildRoot:    %{_tmppath}/%{name}-buildroot
Prefix:       %{_prefix}
Provides:     haskell
Requires:     readline

%description
Hugs 98 is an interpreter for Haskell, a lazy functional programming language.

%prep
%setup -n %{name}-%{version}

%build
cd src/unix
./configure --prefix=%{prefix} --mandir=%{_mandir} --with-fptools=../../fptools ${EXTRA_CONFIGURE_OPTS}
cd ..
make
( cd ../docs/users_guide && make && gzip -f -9 users_guide.{dvi,pdf,ps} )

%install
cd src
make DESTDIR=${RPM_BUILD_ROOT} install_rpm
gzip -f -9 ${RPM_BUILD_ROOT}%{_mandir}/man1/hugs.1
gzip -f -9 ${RPM_BUILD_ROOT}%{_mandir}/man1/hugs-package.1

%files
%defattr(-,root,root)
%doc Credits
%doc License
%doc Readme
%doc docs/ffi-notes.txt
%doc docs/libraries-notes.txt
%doc docs/machugs-notes.txt
%doc docs/packages.txt
%doc docs/server.html
%doc docs/server.tex
%doc docs/winhugs-notes.txt
%doc docs/users_guide/users_guide
%doc docs/users_guide/users_guide.dvi.gz
%doc docs/users_guide/users_guide.pdf.gz
%doc docs/users_guide/users_guide.ps.gz
%{_mandir}/man1/hugs.1.gz
%{_mandir}/man1/hugs-package.1.gz
%{prefix}/bin/ffihugs
%{prefix}/bin/hugs
%{prefix}/bin/hugs-package
%{prefix}/bin/runhugs
%{prefix}/lib/hugs/demos
%{prefix}/lib/hugs/include
%{prefix}/lib/hugs/libraries
%{prefix}/lib/hugs/oldlib
%{prefix}/lib/hugs/tools
