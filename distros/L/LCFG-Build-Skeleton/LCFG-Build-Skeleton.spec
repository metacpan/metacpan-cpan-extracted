Name:           perl-LCFG-Build-Skeleton
Summary:        Tools for generating new LCFG projects
Version:        0.5.0
Release:        1
Packager:       Stephen Quinney <squinney@inf.ed.ac.uk>
License:        GPLv2
Group:          LCFG/Development
Source:         LCFG-Build-Skeleton-0.5.0.tar.gz
BuildArch:	noarch
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildRequires:  perl(Module::Build)
Requires:	perl(LCFG::Build::PkgSpec) >= 0.0.23
Requires:	perl(LCFG::Build::VCS) >= 0.0.26
Requires:	perl(Moose) >= 0.57
Requires:	perl(MooseX::Getopt) >= 0.13
Requires:       perl(Template) >= 2.14
Requires:       perl(UNIVERSAL::require)
Requires:	perl(YAML::Syck) >= 0.98
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This module handles the creation of the skeleton of an LCFG software
project. Typically, it prompts the user to answer a set of standard
questions and then generates the necessary files from a set of
templates. These generated files include the necessary metadata, build
files and, for LCFG components, example code. It can also add the new
project into the revision-control system of choice.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/


%prep
%setup -q -n LCFG-Build-Skeleton-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT
./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%files
%defattr(-,root,root)
%doc ChangeLog
%doc %{_mandir}/man1/*
%doc %{_mandir}/man3/*
%{perl_vendorlib}/LCFG/Build/Skeleton.pm
/usr/share/lcfgbuild/templates/*.tt
/usr/bin/lcfg-skeleton

%clean
rm -rf $RPM_BUILD_ROOT

%changelog
* Tue Feb 24 2015 SVN: new release
- Release: 0.5.0

* Tue Feb 24 2015 11:20 squinney@INF.ED.AC.UK
- bin/lcfg-skeleton.in: help is handled automatically now so don't
  need to do it in the script

* Tue Feb 24 2015 11:16 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: tweaked the configfile handling
  some more to closely match MooseX::ConfigFromFile

* Tue Feb 24 2015 10:59 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: Reworked the configuration file
  handling so that it matches with the newer way of using
  MooseX::ConfigFromFile

* Fri Feb 06 2015 10:23 squinney@INF.ED.AC.UK
- templates/COMPONENT.pod.tt: Improved the POD template

* Mon Dec 08 2014 16:14 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.4.1

* Mon Dec 08 2014 16:14 squinney@INF.ED.AC.UK
- lcfg.yml: Noted EL7 support

* Mon Dec 08 2014 16:13 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.4.0

* Mon Dec 08 2014 16:08 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in, templates/README.perl.tt: Ensure
  the perl lib directory is not empty when the project is not for
  an lcfg component

* Mon Dec 08 2014 16:03 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: fixed perl module suffix

* Mon Dec 08 2014 16:01 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in, templates/perlcomp_cmake.tt: Perl
  components with modules need a cmake file

* Mon Dec 08 2014 15:56 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in, templates/COMPONENT.pl.tt,
  templates/COMPONENT.pm.tt, templates/specfile.tt: Reworked how
  Perl components are generated so that there is a separate module

* Thu Oct 30 2014 14:00 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.3.1

* Thu Oct 30 2014 14:00 squinney@INF.ED.AC.UK
- templates/specfile.tt: updated the template post-install script
  to use the new isstarted om method

* Thu May 22 2014 15:47 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.3.0

* Thu May 22 2014 15:46 squinney@INF.ED.AC.UK
- lcfg.yml, templates/specfile.tt: Updated specfile template to add
  a BuildRequires on lcfg-build-deps for lcfg components. Added the
  install stage removal of empty files. Also set the perl install
  location so that this should work out-of-the-box for more people
  writing perl components

* Thu Feb 27 2014 15:36 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.2.0

* Thu Feb 27 2014 15:33 squinney@INF.ED.AC.UK
- templates/specfile.tt: Do not include a build-dependency on
  /etc/rpm/macros.cmake in the specfile template, this was only
  necessary for SL5 and breaks builds on EL7 and newer Fedora

* Thu Feb 17 2011 18:25 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.1.0

* Thu Feb 17 2011 18:00 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: Email::Address->parse() returns a
  list, we will just take the first entry and ignore the rest

* Thu Feb 17 2011 17:54 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: Added code to sanitise the author
  email address, hopefully this fixes
  https://bugs.lcfg.org/show_bug.cgi?id=386

* Thu Feb 17 2011 17:14 squinney@INF.ED.AC.UK
- lib/LCFG/Build/Skeleton.pm.in: Added validation of component
  name. Closes https://bugs.lcfg.org/show_bug.cgi?id=339

* Thu Feb 17 2011 17:09 squinney@INF.ED.AC.UK
- templates/specfile.tt: Include the templates directory. Closes
  https://bugs.lcfg.org/show_bug.cgi?id=372

* Mon Apr 12 2010 15:57 squinney@INF.ED.AC.UK
- ChangeLog, lcfg.yml: LCFG-Build-Skeleton release: 0.0.13

* Mon Apr 12 2010 15:57 squinney@INF.ED.AC.UK
- templates/specfile.tt: Removed lsb from the specfile template

* Wed Mar 11 2009 13:26 squinney@INF.ED.AC.UK
- bin/lcfg-skeleton.in, lib/LCFG/Build/Skeleton.pm.in: Set
  svn:keywords on the LCFG::Build::Skeleton Perl modules and
  scripts

* Mon Mar 09 2009 16:43 squinney
- lcfg.yml: Removed hardwired version-control type from lcfg.yml to
  allow future transfer to subversion

* Mon Mar 09 2009 15:37 squinney
- ChangeLog, lcfg.yml: Release: 0.0.12

* Mon Mar 09 2009 15:36 squinney
- lcfg.yml, lib/LCFG/Build/Skeleton.pm.in: Before creating a new
  project check that a local file/dir with the required name does
  not exist. Also use the new API for import_project() in
  LCFG::Build::VCS 0.0.26

* Mon Mar 09 2009 15:22 squinney
- LCFG-Build-Skeleton.spec: Increased minimum dependency on
  LCFG::Build::VCS to >= 0.0.26

* Mon Mar 09 2009 12:37 squinney
- ChangeLog, lcfg.yml: Release: 0.0.11

* Mon Mar 09 2009 12:37 squinney
- lcfg.yml, lib/LCFG/Build/Skeleton.pm.in: Added support for SVN.
  Slightly reworked the way in which projects are created so that
  it happens in a temporary directory. Also no longer hardwire the
  version-control system choice so that it can be easily changed
  later. This is all much cleaner and saner.

* Tue Jan 06 2009 12:09 squinney
- ChangeLog, lcfg.yml: Release: 0.0.10

* Tue Jan 06 2009 12:09 squinney
- lib/LCFG/Build/Skeleton.pm.in, templates/README.nagios.tt,
  templates/README.templates.tt: Added README files for the nagios
  and templates directories. This is
  useful info for new users but also provides files so that "cvs
  import"
  will actually add the directories to the repository.

* Fri Dec 05 2008 12:14 squinney
- ChangeLog, lcfg.yml: Release: 0.0.9

* Fri Dec 05 2008 12:13 squinney
- lib/LCFG/Build/Skeleton.pm.in: Automatically create templates and
  nagios directories for LCFG components

* Fri Sep 12 2008 10:39 squinney
- ChangeLog, lcfg.yml: Release: 0.0.8

* Fri Sep 12 2008 10:39 squinney
- lcfg.yml, lib/LCFG/Build/Skeleton.pm.in: Fixed bug with setting
  the list of questions. Renamed 'rcs' attribute to 'vcs' to be
  consistent with how it is named in the rest of the build tools

* Thu Sep 11 2008 19:06 squinney
- ChangeLog, lcfg.yml: Release: 0.0.7

* Thu Sep 11 2008 19:06 squinney
- bin/lcfg-skeleton.in, lib/LCFG/Build/Skeleton.pm.in: Modified
  some file path handling to use File::Spec

* Thu Sep 11 2008 15:23 squinney
- t, t/01_load.t: Added a really basic test to see that the
  Skeleton module actually loads

* Thu Sep 11 2008 15:21 squinney
- Makefile.PL: Added missing comma in Makefile.PL dependency list

* Thu Sep 11 2008 09:20 squinney
- ChangeLog, lcfg.yml: Release: 0.0.6

* Thu Sep 11 2008 09:20 squinney
- META.yml.in: Fixed error in META.yml which upsets the pause
  indexer

* Wed Sep 10 2008 18:34 squinney
- ChangeLog, lcfg.yml: Release: 0.0.5

* Wed Sep 10 2008 18:31 squinney
- META.yml.in: Modified META.yml to attempt to avoid pause wrongly
  indexing template files

* Wed Sep 10 2008 14:19 squinney
- ChangeLog, lcfg.yml: Release: 0.0.4

* Wed Sep 10 2008 14:19 squinney
- Build.PL.in, LCFG-Build-Skeleton.spec, MANIFEST, META.yml.in,
  Makefile.PL, README, bin/lcfg-skeleton.in, lcfg.yml,
  lib/LCFG/Build/Skeleton.pm.in: Lots of improvements to the
  documentation. Some code tidying to satisfy perltidy and
  perlcritic.

* Mon Sep 08 2008 10:47 squinney
- templates/specfile.tt: Fixed various conditional sections in the
  specfile template

* Thu Sep 04 2008 11:47 squinney
- ChangeLog, lcfg.yml: Release: 0.0.3

* Thu Sep 04 2008 11:47 squinney
- Build.PL.in, LCFG-Build-Skeleton.spec, MANIFEST, META.yml.in,
  Makefile.PL, README, README.BUILD, bin, bin/lcfg-skeleton.in,
  lcfg.yml, lib/LCFG/Build/Skeleton.pm.in, specfile: Fully
  converted module to using Module::Build

* Thu Sep 04 2008 09:42 squinney
- ChangeLog, lcfg.yml: Release: 0.0.2

* Thu Sep 04 2008 09:40 squinney
- Build.PL.in, MANIFEST, lib, lib/LCFG, lib/LCFG/Build,
  lib/LCFG/Build/Skeleton.pm.in, templates,
  templates/COMPONENT.def.tt, templates/COMPONENT.pl.tt,
  templates/COMPONENT.pod.tt, templates/COMPONENT.sh.tt,
  templates/ChangeLog.tt, templates/README.BUILD.tt,
  templates/README.tt, templates/specfile.tt: Copied over various
  files from the original project tree. Also converted to using the
  perl Module::Build system to make it the same as the other LCFG
  build tool modules.

* Thu Sep 04 2008 09:08 squinney
- ChangeLog, README, README.BUILD, lcfg.yml, specfile: Created with
  lcfg-skeleton

* Thu Sep 04 2008 09:08 
- .: Standard project directories initialized by cvs2svn.


