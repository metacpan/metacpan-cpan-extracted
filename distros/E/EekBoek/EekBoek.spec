# -*- rpm-spec -*-

################ Build Options ###################
%define dbtests 1
%{?_with_dbtests:    %{expand: %%global dbtests 1}}
%{?_without_dbtests: %{expand: %%global dbtests 0}}
################ End Build Options ################

Name: EekBoek
Summary: Bookkeeping software for small and medium-size businesses
License: GPL+ or Artistic
Group: Applications/Productivity
Version: 2.02.04
Release: 1%{?dist}
Source: http://www.eekboek.nl/dl/%{name}-%{version}.tar.gz
URL: http://www.eekboek.nl
BuildRoot: %{_tmppath}/rpm-buildroot-%{name}-%{version}-%{release}

# The package name is CamelCased. However, for convenience some
# of its data is located in files and directories that are all
# lowercase. See the %%install section.
%global lcname eekboek

# It's all plain perl, nothing architecture dependent.
BuildArch: noarch

# This package would provide many (perl) modules, but these are
# note intended for general use.
AutoReqProv: 0

Requires: perl >= 5.8
Requires: perl(Archive::Zip)
Requires: perl(HTML::Parser)
Requires: perl(Term::ReadLine)
Requires: perl(Term::ReadLine::Gnu)
Requires: perl(DBI) >= 1.40
Requires: perl(DBD::SQLite) >= 1.12
Requires: perl(Carp::Assert) >= 0.20

BuildRequires: perl >= 5.8.8
BuildRequires: perl(Module::Build) >= 0.32
BuildRequires: perl(IPC::Run3)
BuildRequires: perl(Archive::Zip)
BuildRequires: perl(HTML::Parser)
BuildRequires: perl(Term::ReadLine)
BuildRequires: perl(Term::ReadLine::Gnu)
BuildRequires: perl(DBI) >= 1.40
BuildRequires: perl(DBD::SQLite) >= 1.12
BuildRequires: perl(Carp::Assert) >= 0.20
BuildRequires: perl(Test::More)
BuildRequires: desktop-file-utils
BuildRequires: zip

Obsoletes: %{name}-core < 2.00.01
Obsoletes: %{name}-contrib < 2.00.01
Conflicts: %{name}-core < 2.00.01

# For symmetry.
%global __zip   /usr/bin/zip
%global __rmdir /bin/rmdir
%global __find  /usr/bin/find

%description
EekBoek is a bookkeeping package for small and medium-size businesses.
Unlike other accounting software, EekBoek has both a command-line
interface (CLI) and a graphical user-interface (GUI, currently under
development and not included in this package). Furthermore, it has a
complete Perl API to create your own custom applications. EekBoek is
designed for the Dutch/European market and currently available in
Dutch only. An English translation is in the works (help appreciated).

EekBoek can make use of several database systems for its storage.
Support for the SQLite database is included.

For GUI support, install %{name}-gui.

For production use, you are invited to install the %{name}-db-postgresql
database package.

%package gui

Summary: %{name} graphical user interface
Group: Applications/Productivity
AutoReqProv: 0

Requires: %{name} = %{version}-%{release}
Requires: perl(Wx) >= 0.89
Requires: wxGTK >= 2.8.8
Requires: gettext

%description gui
This package contains the wxWidgets (GUI) extension for %{name}.

%package db-postgresql

# This package only contains the necessary module(s) for EekBoek
# to use the PostgreSQL database.
# Installing this package will pull in the main package and
# the Perl PostgreSQL modules, if necessary.
# No %%doc required.

Summary: PostgreSQL database driver for %{name}
Group: Applications/Productivity
AutoReqProv: 0
Requires: %{name} = %{version}-%{release}
Requires: perl(DBD::Pg) >= 1.41

%description db-postgresql
EekBoek can make use of several database systems for its storage.
This package contains the PostgreSQL database driver for %{name}.

%prep
%setup -q

chmod 0664 MANIFEST

# Remove some build helper sources since we BuildRequire them.
%{__rm} -fr inc/IPC inc/Module
%{__perl} -ni~ -e 'print unless m;^inc/(Module|IPC)/;;' MANIFEST

# Remove some library modules since we Require them.
%{__rm} -fr lib/EB/CPAN/Carp
%{__rm} -fr lib/EB/CPAN/Wx
%{__perl} -ni~ -e 'print unless m;^lib/EB/CPAN/;;' MANIFEST

%build
%{__perl} Build.PL
%{__perl} Build

# Move some files into better places.
%{__mkdir} examples
%{__mv} emacs/eekboek-mode.el examples

%install
%{__rm} -rf %{buildroot}

# Short names for our libraries.
%global ebconf  %{_sysconfdir}/%{lcname}
%global ebshare %{_datadir}/%{name}-%{version}

%{__mkdir_p} %{buildroot}%{ebconf}
%{__mkdir_p} %{buildroot}%{ebshare}/lib
%{__mkdir_p} %{buildroot}%{_bindir}

# Install the default, system-wide config file.
%{__install} -p -m 0644 blib/lib/EB/examples/%{lcname}.conf %{buildroot}%{ebconf}/%{lcname}.conf

# Install locales.
for lang in blib/lib/EB/res/locale/*
do
  l=`basename ${lang}`
  %{__mkdir_p} %{buildroot}%{_datadir}/locale/${l}/LC_MESSAGES
  %{__mv} blib/lib/EB/res/locale/${l}/* %{buildroot}%{_datadir}/locale/${l}/LC_MESSAGES
  %{__rmdir} blib/lib/EB/res/locale/${l}
done
%{__rmdir} blib/lib/EB/res/locale

# Create lib dirs and copy files.
%{__find} blib/lib -type d -printf "%{__mkdir} %{buildroot}%{ebshare}/lib/%%P\n" | sh -x
%{__find} blib/lib ! -type d -printf "%{__install} -p -m 0644 %p %{buildroot}%{ebshare}/lib/%%P\n" | sh -x

for script in ebshell ebwxshell
do

  # Create the main scripts.
  echo "#!%{__perl}" > %{buildroot}%{_bindir}/${script}
  %{__sed} -s "s;# use lib qw(EekBoekLibrary;use lib qw(%{ebshare}/lib;" \
    < script/${script} >> %{buildroot}%{_bindir}/${script}
  %{__chmod} 0755 %{buildroot}%{_bindir}/${script}

  # And its manual page.
  %{__mkdir_p} %{buildroot}%{_mandir}/man1
  pod2man blib/script/${script} > %{buildroot}%{_mandir}/man1/${script}.1

done

# Handle localisations separately since we are not complete yet.
for script in ebcore
do
  %find_lang ${script}
done

# Desktop file, icons, ...
%{__mkdir_p} %{buildroot}%{_datadir}/pixmaps
%{__install} -p -m 0664 lib/EB/res/Wx/icons/ebicon.png %{buildroot}%{_datadir}/pixmaps/
for script in ebwxshell
do
  desktop-file-install --delete-original \
    --dir=%{buildroot}%{_datadir}/applications ${script}.desktop
  desktop-file-validate %{buildroot}/%{_datadir}/applications/${script}.desktop
done

# End of install section.

%check
%if %{dbtests}
%{__perl} Build test
%else
%{__perl} Build test --skipdbtests
%endif

%clean
%{__rm} -rf %{buildroot}

%files -f ebcore.lang
%defattr(-,root,root,-)
%doc CHANGES README examples/ doc/html/ TODO
%dir %{_sysconfdir}/%{lcname}
%config(noreplace) %{_sysconfdir}/%{lcname}/%{lcname}.conf
%{ebshare}/
%exclude %{ebshare}/lib/EB/DB/Postgres.pm
%exclude %{ebshare}/lib/EB/Wx
%{_bindir}/ebshell
%{_mandir}/man1/ebshell*

%files gui
%defattr(-,root,root,-)
%doc README.gui
%{ebshare}/lib/EB/Wx
%{_bindir}/ebwxshell
%{_mandir}/man1/ebwxshell*
%{_datadir}/applications/ebwxshell.desktop
%{_datadir}/pixmaps/ebicon.png

%files db-postgresql
%defattr(-,root,root,-)
%doc README.postgres
%{ebshare}/lib/EB/DB/Postgres.pm

%changelog
* Thu Sep 13 2012 Johan Vromans <jvromans@squirrel.nl> - 2.01.06-1
- Upgrade to upstream 2.01.06.

* Fri Jul 09 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.02-2
- Adjust emacs support files.

* Thu May 06 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.02-1
- Upgrade to upstream 2.00.02.

* Mon Mar 29 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.01-3
- More Obsoletes.

* Mon Mar 29 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.01-2
- Fix duplicate %%description.
- Fix BuildRequires and Obsoletes.

* Sun Mar 28 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.01-1
- Upgrade to upstream 2.00.01.

* Sat Mar 27 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.00-2
- Repackage according to user concensus.

* Tue Mar 23 2010 Johan Vromans <jvromans@squirrel.nl> - 2.00.00-1
- Upgrade to upstream 2.00.00.

* Mon Feb 08 2010 Johan Vromans <jvromans@squirrel.nl> - 1.05.20-1
- Upgrade to upstream 1.05.20.

* Sat Jan 16 2010 Johan Vromans <jvromans@squirrel.nl> - 1.05.16-1
- Upgrade to upstream 1.05.16.

* Fri Jan 15 2010 Johan Vromans <jvromans@squirrel.nl> - 1.05.15-2
- Add missing file to db-postgres package.

* Fri Jan 15 2010 Johan Vromans <jvromans@squirrel.nl> - 1.05.15-1
- Upgrade to upstream 1.05.15.

* Fri Jan 15 2010 Johan Vromans <jvromans@squirrel.nl> - 1.05.14-1
- Upgrade to upstream 1.05.14.
- Re-structure the package into several subpackages.

* Wed Jan 06 2010 Johan Vromans <jvromans@squirrel.nl> - 1.04.06-1
- Upgrade to upstream 1.04.06.

* Mon Dec 28 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.05-2
- Fix for table detection with newer SQLite.

* Mon Dec 28 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.05-1
- Upgrade to upstream 1.04.05.

* Fri Jul 24 2009 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.04.04-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_12_Mass_Rebuild

* Fri Jun 19 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.04-1
- Upgrade to upstream 1.04.04.
- Obsolete script patch.
- Obsolete conversion to UTF-8 of README.

* Wed Apr 22 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.03-3
- Remove Epoch: since it it not needed.
- Make subpackage depend on EVR.

* Mon Apr 20 2009 Johan Vromans <jvromans@squirrel.nl> - 1:1.04.03-2
- Use Epoch: to tighten dependency between basepackage and subpackage.
- Use %%global instead of %%define.
- Provide README.postgres as source, not as a patch.
- Keep timestamps when copying and installing.
- Simplify filelist building.
- Remove INSTALL from %%doc.

* Fri Apr 17 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.03-1
- Upgrade to upstream 1.04.03.
- Include SQLite with the base package.
- Enable database tests since we now require a db driver.

* Fri Jan 30 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.02-1
- Adapt to Fedora guidelines

* Sun Jan 26 2009 Johan Vromans <jvromans@squirrel.nl> - 1.04.02
- Remove QUICKSTART.

* Sat Jul 19 2008 Johan Vromans <jvromans@squirrel.nl> - 1.03.90
- Remove debian stuff
- Don't use unstable.

* Fri Apr 11 2008 Johan Vromans <jvromans@squirrel.nl> - 1.03.12
- Simplify by setting variables from the .in template

* Sun Apr 01 2007 Johan Vromans <jvromans@squirrel.nl> - 1.03.03
- Exclude some Wx files.

* Sun Nov 05 2006 Johan Vromans <jvromans@squirrel.nl> - 1.03.00
- Move DB drivers to separate package, and adjust req/prov.

* Mon Oct 16 2006 Johan Vromans <jvromans@squirrel.nl> - 1.01.02
- Prepare (but don't use) suffixes to separate production and unstable versions.

* Wed Aug 02 2006 Johan Vromans <jvromans@squirrel.nl> 0.92
- New URL. Add Vendor.

* Fri Jun 09 2006 Johan Vromans <jvromans@squirrel.nl> 0.60
- Remove man3.

* Thu Jun 08 2006 Johan Vromans <jvromans@squirrel.nl> 0.60
- Fix example.

* Mon Jun 05 2006 Johan Vromans <jvromans@squirrel.nl> 0.59
- Better script handling.

* Mon Apr 17 2006 Johan Vromans <jvromans@squirrel.nl> 0.56
- Initial provisions for GUI.

* Wed Apr 12 2006 Johan Vromans <jvromans@squirrel.nl> 0.56
- %%config(noreplace) for eekboek.conf.

* Tue Mar 28 2006 Johan Vromans <jvromans@squirrel.nl> 0.52
- Perl Independent Install

* Mon Mar 27 2006 Johan Vromans <jvromans@squirrel.nl> 0.52
- Add "--with dbtests" parameter for rpmbuild.
- Resultant rpm may be signed.

* Sun Mar 19 2006 Johan Vromans <jvromans@squirrel.nl> 0.50
- Switch to Build.PL instead of Makefile.PL.

* Mon Jan 30 2006 Johan Vromans <jvromans@squirrel.nl> 0.37
- Add build dep perl(Config::IniFiles).

* Fri Dec 23 2005 Wytze van der Raay <wytze@nlnet.nl> 0.23
- Fixes for x86_64 building problems.

* Wed Dec 12 2005 Johan Vromans <jvromans@squirrel.nl> 0.22
- Change some wordings.
- Add man1.

* Tue Dec 11 2005 Johan Vromans <jvromans@squirrel.nl> 0.21
- Add INSTALL QUICKSTART

* Thu Dec 08 2005 Johan Vromans <jvromans@squirrel.nl> 0.20
- Include doc/html.

* Tue Nov 22 2005 Johan Vromans <jvromans@squirrel.nl> 0.19
- More.

* Sun Nov 20 2005 Jos Vos <jos@xos.nl> 0.17-XOS.0beta1
- Initial version.
