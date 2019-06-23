Name:           perl-LCFG-Build-VCS
Version:        0.3.9
Release:        1
Summary:        LCFG version control infrastructure
License:        GPLv2
Group:          Development/Libraries
Source0:        LCFG-Build-VCS-0.3.9.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl >= 5.10.0
BuildRequires:  perl(Module::Build), perl(Test::More)
BuildRequires:  perl(Moose) >= 0.57
BuildRequires:  perl(File::HomeDir) >= 0.58
BuildRequires:	perl(File::Copy::Recursive) >= 0.36
BuildRequires:	perl(DateTime)
BuildRequires:  perl(IPC::Run), perl(URI), perl(Try::Tiny)
BuildRequires:  perl(Template) >= 2.14
Requires:       perl(Template) >= 2.14
Requires:       perl(Moose) >= 0.57
Requires:	perl(File::Copy::Recursive) >= 0.36
Requires:       cvs, cvs2cl
Requires:	subversion, svn2cl
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This is a suite of tools designed to provide a standardised interface
to version-control systems so that the LCFG build tools can deal with
project version-control in a high-level abstract fashion. Typically
they provide support for procedures such as importing and exporting
projects, doing tagged releases, generating the project changelog from
the version-control log and checking all changes are committed.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/


%prep
%setup -q -n LCFG-Build-VCS-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes README
%{perl_vendorlib}/LCFG/Build/VCS.pm
%{perl_vendorlib}/LCFG/Build/VCS/CVS.pm
%{perl_vendorlib}/LCFG/Build/VCS/None.pm
%{perl_vendorlib}/LCFG/Build/VCS/SVN.pm
%doc %{_mandir}/man3/*

%changelog
* Fri Mar 22 2019 SVN: new release
- Release: 0.3.9

* Fri Mar 22 2019 15:55  squinney@INF.ED.AC.UK
- debian/control: Need to build-depend on libmodule-build-perl

* Fri Jan 18 2019 10:23  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-VCS release: 0.3.8

* Fri Jan 18 2019 10:22  squinney@INF.ED.AC.UK
- Makefile.PL: Updated build script

* Fri Jan 18 2019 10:21  squinney@INF.ED.AC.UK
- META.json.in, META.yml.in, lcfg.yml: Updated cpan metadata

* Fri Jan 18 2019 10:10  squinney@INF.ED.AC.UK
- debian/control: fixed Build-Depends-Indep

* Fri Jan 18 2019 10:10  squinney@INF.ED.AC.UK
- Build.PL.in: minor tweaks to how dep versions are specified

* Fri Jan 18 2019 10:09  squinney@INF.ED.AC.UK
- README: updated instructions

* Fri Jan 18 2019 10:07  squinney@INF.ED.AC.UK
- LCFG-Build-VCS.spec: updated minimum perl version

* Fri Jan 18 2019 10:07  squinney@INF.ED.AC.UK
- debian/control: Added perl modules to build-deps so tests can be run

* Fri Jan 18 2019 10:01  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/CVS.pm.in, lib/LCFG/Build/VCS/None.pm.in,
  lib/LCFG/Build/VCS/SVN.pm.in: Set minimum perl version to 5.10

* Thu Jan 17 2019 12:02  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-VCS release: 0.3.7

* Thu Jan 17 2019 12:01  squinney@INF.ED.AC.UK
- Changes, lcfg.yml, lib/LCFG/Build/VCS.pm.in: Fixed calls to
  update_debian_changelog and update_lcfg_changelog from update_changelog

* Thu Jan 17 2019 11:59  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-VCS.spec, debian/control, lcfg.yml: Added new
  dependency on Template Toolkit

* Thu Jan 17 2019 11:57  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Extracted the functionality for updating debian
  changelog files so that it can be used elsewhere

* Wed Jan 16 2019 20:13  squinney@INF.ED.AC.UK
- debian/control: Changed binary package name to liblcfg-build-vcs-perl to
  be standard style for perl packages

* Tue Jan 15 2019 16:37  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-VCS release: 0.3.5

* Tue Jan 15 2019 16:36  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/None.pm.in: specify minimum dep on some modules

* Tue Jan 15 2019 16:36  squinney@INF.ED.AC.UK
- debian/control: recommend subversion, suggest cvs

* Tue Jan 15 2019 16:36  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Fixed POD errors

* Tue Jan 15 2019 16:29  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-VCS release: 0.3.4

* Tue Jan 15 2019 16:29  squinney@INF.ED.AC.UK
- debian, debian/compat, debian/control, debian/copyright, debian/docs,
  debian/rules, debian/source, debian/source/format, lcfg.yml, t/01_load.t:
  Added debian packaging metadata

* Tue Jan 08 2019 14:31  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.3.3

* Fri Jan 04 2019 16:53  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.3.2

* Fri Jan 04 2019 16:49  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Fixed package name handling for
  debian/changelog

* Wed Dec 12 2018 15:04  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.3.1

* Wed Dec 12 2018 15:03  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/VCS.pm.in: Need to add debian/changelog file to
  the repository if it is new

* Wed Dec 12 2018 14:57  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.3.0

* Wed Dec 12 2018 14:57  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-VCS.spec, META.yml.in, lcfg.yml: Use a safer
  macro for the package version

* Wed Dec 12 2018 14:57  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Added support to update_changelog for updating
  a debian/changelog file

* Mon Nov 20 2017 14:52  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.5

* Mon Nov 20 2017 14:52  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/VCS.pm.in: store_version now reports what it is
  doing

* Mon Nov 20 2017 14:25  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.4

* Mon Nov 20 2017 14:25  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Added new store_version method which can be
  used to store version string into a file when project is tagged

* Thu Jan 19 2017 13:33  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.3

* Thu Jan 19 2017 13:31  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/SVN.pm.in: Converted binpath from an absolute path to
  a general string. This relies on the command being found within the PATH
  which works better on platforms (e.g. MacOSX) where svn is installed in
  an unusual location

* Thu Nov 12 2015 15:42  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.2

* Thu Nov 12 2015 15:42  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/None.pm.in, lib/LCFG/Build/VCS/SVN.pm.in: Dropped
  fully-qualified paths for svn2cl and cvs2cl so that the tools work on
  MacOSX, closes: https://bugs.lcfg.org/show_bug.cgi?id=919

* Fri Oct 11 2013 12:54  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.1

* Fri Oct 11 2013 12:45  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/CVS.pm.in: documented the auto_detect method

* Fri Oct 11 2013 12:40  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.2.0

* Fri Oct 11 2013 12:34  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/VCS/CVS.pm.in: Added a rather stupid
  auto-detection method for CVS which just looks for the presence of a
  CVS/Root file in the specified directory

* Tue Oct 08 2013 16:17  squinney@INF.ED.AC.UK
- LCFG-Build-VCS.spec, lib/LCFG/Build/VCS/SVN.pm.in: Added a new
  auto_detect method which returns a boolean value which indicates whether
  or not a directory is part of an svn working copy

* Tue Oct 08 2013 15:38  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in: Tweaked error message on absolute path type so
  it is less confusing

* Tue Aug 27 2013 10:48  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.6

* Tue Aug 27 2013 10:46  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/SVN.pm.in: need to
  run 'svn up' before using svn2cl to ensure we get all the log messages

* Fri Aug 23 2013 10:29  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.5

* Fri Aug 23 2013 10:25  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Fixed the genchangelog method so that it
  builds the correct changelog for branches rather than just always using
  trunk. Fixes https://bugs.lcfg.org/show_bug.cgi?id=669

* Sat May 19 2012 14:52  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.4

* Sat May 19 2012 14:52  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Reworked the way the repository url path is
  split. This should be much more reliable as this does not have any
  hardwired knowledge about repository structure. The only requirement now
  is that branches, tags and trunk directories are at the same level in the
  hierarchy

* Sat May 19 2012 07:46  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.3

* Sat May 19 2012 07:46  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-VCS.spec, META.yml.in, Makefile.PL, README: Added
  dependency on URI module

* Sat May 19 2012 07:34  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.2

* Sat May 19 2012 07:28  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Reworked the way we build the paths to
  trunk and tags directories. This hopefully fixes
  https://bugs.lcfg.org/show_bug.cgi?id=563 by removing the requirement
  that trunk and tags directories are at the top-level of the repository

* Mon Jul 12 2010 11:10  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.1

* Mon Jul 12 2010 11:10  squinney@INF.ED.AC.UK
- LCFG-Build-VCS.spec: Build-requires perl(Test::More)

* Mon Jul 12 2010 11:03  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.1.0

* Mon Jul 12 2010 11:01  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Do an 'update' before a 'copy' when tagging
  the project at a particular version. This fixes
  https://bugs.lcfg.org/show_bug.cgi?id=302

* Mon Jul 12 2010 10:42  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/None.pm.in: Fixed the checkcommitted() method so that
  it returns true

* Thu Apr 09 2009 09:34  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.0.33

* Thu Apr 09 2009 09:34  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-VCS.spec, META.yml.in, Makefile.PL, README:
  Forgot to add build-dependency on perl(File::HomeDir). Also added it to
  the dependency lists in the CPAN metadata files

* Thu Apr 09 2009 09:25  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.0.32

* Thu Apr 09 2009 09:25  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/VCS/None.pm.in: Implemented import_project() and
  checkout_project() so that LCFG::Build::Skeleton will work with the None
  module

* Wed Mar 25 2009 16:26  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.0.31

* Wed Mar 25 2009 16:26  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Altered genchangelog to hopefully make the
  changelog complete

* Fri Mar 13 2009 15:16  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-VCS release: 0.0.30

* Fri Mar 13 2009 15:11  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-VCS.spec, META.yml.in, Makefile.PL, README,
  lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/None.pm.in: Tidied up the dependencies

* Wed Mar 11 2009 13:24  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/None.pm.in, lib/LCFG/Build/VCS/SVN.pm.in: Set
  svn:keywords on the LCFG::Build::VCS Perl modules

* Wed Mar 11 2009 12:29  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: Release: 0.0.29

* Wed Mar 11 2009 12:29  squinney@INF.ED.AC.UK
- lib/LCFG/Build/VCS/SVN.pm.in: Altered commit message for release tagging

* Tue Mar 10 2009 13:21  squinney
- Changes, lcfg.yml: Release: 0.0.28

* Tue Mar 10 2009 13:16  squinney
- lib/LCFG/Build/VCS/SVN.pm.in: tagversion now copies the working copy
  rather than the trunk url which seems to avoid some problems

* Mon Mar 09 2009 16:23  squinney
- Changes, lcfg.yml: Release: 0.0.27

* Mon Mar 09 2009 16:23  squinney
- LCFG-Build-VCS.spec: Added missing build-dependency on IPC::Run

* Mon Mar 09 2009 15:34  squinney
- Changes, lcfg.yml: Release: 0.0.26

* Mon Mar 09 2009 15:34  squinney
- lcfg.yml, lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/SVN.pm.in: Various bug fixes and improvements for the
  CVS and SVN import_project() methods

* Mon Mar 09 2009 14:40  squinney
- Changes, lcfg.yml: Release: 0.0.25

* Mon Mar 09 2009 14:39  squinney
- lcfg.yml, lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/SVN.pm.in: With
  subversion prior to exporting from a url it is necessary to check that
  the url actually exists

* Mon Mar 09 2009 14:09  squinney
- Changes, lcfg.yml: Release: 0.0.24

* Mon Mar 09 2009 14:09  squinney
- lcfg.yml, lib/LCFG/Build/VCS/SVN.pm.in, t/01_load.t: Implemented
  checkout_project and import_project for SVN

* Mon Mar 09 2009 12:02  squinney
- Changes, lcfg.yml: Release: 0.0.23

* Fri Mar 06 2009 18:27  squinney
- Changes, lcfg.yml: Release: 0.0.22

* Fri Mar 06 2009 18:26  squinney
- lcfg.yml, lib/LCFG/Build/VCS/CVS.pm.in: fixed override of build_cmd in
  LCFG::Build::VCS::CVS

* Fri Mar 06 2009 18:26  squinney
- LCFG-Build-VCS.spec: Added LCFG/Build/VCS/SVN.pm to the specfile

* Fri Mar 06 2009 18:14  squinney
- LCFG-Build-VCS.spec, MANIFEST, README: Depend on subversion and svn2cl in
  the specfile. Document new deps in the README

* Fri Mar 06 2009 18:14  squinney
- lib/LCFG/Build/VCS/CVS.pm.in: LCFG::Build::VCS::CVS use the new run_cmd
  and mirror_file methods.

* Fri Mar 06 2009 18:11  squinney
- lib/LCFG/Build/VCS.pm.in: Promoted build_cmd and run_cmd to
  LCFG::Build::VCS and use IPC::Run. Added mirror_file() to
  LCFG::Build::VCS for mirroring files between the working copy and a build
  directory.

* Fri Mar 06 2009 18:08  squinney
- lib/LCFG/Build/VCS/SVN.pm.in: Added first pass at subversion support

* Fri Sep 12 2008 09:46  squinney
- Changes, lcfg.yml: Release: 0.0.21

* Fri Sep 12 2008 09:45  squinney
- lcfg.yml, lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in: Turns
  out that doing a chown on files for the export_devel() method in the CVS
  module was pointless and slightly broken. The checkout_project() method
  was also altered so that if no version is specified it just checks out
  the main project.

* Wed Sep 10 2008 13:48  squinney
- Changes, lcfg.yml: Release: 0.0.20

* Wed Sep 10 2008 13:45  squinney
- Build.PL.in, LCFG-Build-VCS.spec, MANIFEST, META.yml, META.yml.in,
  Makefile.PL, README, lcfg.yml, lib/LCFG/Build/VCS.pm.in,
  lib/LCFG/Build/VCS/CVS.pm.in, lib/LCFG/Build/VCS/None.pm.in, mk: Code
  clean-ups to try and make the path-handling more platform-independent.
  Lots of documentation improvements. Updated various dependencies.

* Wed Sep 03 2008 14:54  squinney
- Changes, lcfg.yml: Release: 0.0.19

* Wed Sep 03 2008 14:52  squinney
- LCFG-Build-VCS.spec: needed to be specific about version of the
  build-dependency on File::Copy::Recursive

* Wed Sep 03 2008 14:37  squinney
- Changes, lcfg.yml: Release: 0.0.18

* Wed Sep 03 2008 14:31  squinney
- Build.PL.in, LCFG-Build-VCS.spec, META.yml, Makefile.PL, lcfg.yml: Added
  dependency on File::Copy::Recursive

* Wed Sep 03 2008 14:21  squinney
- Changes, lcfg.yml: Release: 0.0.17

* Wed Sep 03 2008 14:21  squinney
- lcfg.yml, lib/LCFG/Build/VCS.pm.in, lib/LCFG/Build/VCS/CVS.pm.in,
  lib/LCFG/Build/VCS/None.pm.in, t/01_load.t: Added methods to support
  basic import and checkout for projects

* Thu Aug 14 2008 09:53  squinney
- Changes, lcfg.yml: Release: 0.0.16

* Thu Aug 14 2008 09:51  squinney
- MANIFEST, lcfg.yml, lib/LCFG/Build/VCS.pm.in,
  lib/LCFG/Build/VCS/CVS.pm.in: Moved the update_changelog method from the
  CVS module to a higher level so it can be used by other modules

* Thu Aug 14 2008 09:50  squinney
- lib/LCFG/Build/VCS/None.pm.in: Added support for a 'None' VCS module
  which just uses the filesystem

* Tue Jun 24 2008 13:46  squinney
- Changes, lcfg.yml: Release: 0.0.15

* Tue Jun 24 2008 13:46  squinney
- Build.PL, Build.PL.in, LCFG-Build-VCS.spec, lcfg.yml,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS.pm.in,
  lib/LCFG/Build/VCS/CVS.pm, lib/LCFG/Build/VCS/CVS.pm.in: switched to
  pre-processed files to get automated setting of version, author, etc.

* Mon Jun 23 2008 14:43  squinney
- Changes, lcfg.yml: Release: 0.0.14

* Mon Jun 23 2008 14:42  squinney
- Build.PL, Build.PL.in, LCFG-Build-VCS.spec, MANIFEST, META.yml, README,
  lcfg.yml, lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Fixed problem with finding relevant files for
  export_devel() for CVS where the list could contain deleted files waiting
  a commit

* Mon Jun 23 2008 12:38  squinney
- Build.PL, Changes, META.yml, README, lcfg.yml, lib/LCFG/Build/VCS.pm,
  lib/LCFG/Build/VCS/CVS.pm, perl-LCFG-Build-VCS.spec: Release: 0.0.13

* Mon Jun 23 2008 12:34  squinney
- META.yml, README, lcfg.yml, lib/LCFG/Build/VCS.pm,
  lib/LCFG/Build/VCS/CVS.pm: Added support for a dry-run where commands are
  not actually executed. Also did some code tidying and checked with
  perlcritic

* Thu May 29 2008 10:04  squinney
- Build.PL, lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Modified the CVS export and export_devel
  methods to return the name of the created directory

* Tue May 13 2008 11:46  squinney
- perl-LCFG-Build-VCS.spec: no longer have any man1 files

* Tue May 13 2008 11:40  squinney
- Build.PL, Changes, MANIFEST, META.yml, Makefile.PL, README, lcfg.yml,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Release: 0.0.11

* Tue May 13 2008 11:02  squinney
- META.yml, bin, perl-LCFG-Build-VCS.spec: Moved lcfg-reltool to
  LCFG-Build-Tools to simplify dependencies

* Fri Mar 07 2008 14:27  squinney
- Build.PL, Changes, META.yml, README, bin/lcfg-reltool, lcfg.yml,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Release: 0.0.10

* Thu Mar 06 2008 10:22  squinney
- Build.PL, Changes, META.yml, README, bin/lcfg-reltool, lcfg.yml,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Release: 0.0.9

* Thu Mar 06 2008 10:09  squinney
- Makefile.PL: cleaned Makefile.PL

* Tue Mar 04 2008 11:48  squinney
- Build.PL, Changes, META.yml, Makefile.PL, README, bin/lcfg-reltool,
  lcfg.yml, lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Release: 0.0.8

* Tue Mar 04 2008 11:42  squinney
- lib/LCFG/Build/VCS/CVS.pm: fixed export method for cvs

* Tue Mar 04 2008 10:29  squinney
- Build.PL, Changes, META.yml, Makefile.PL, README, bin/lcfg-reltool,
  lcfg.yml, lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: Release: 0.0.7

* Tue Mar 04 2008 10:25  squinney
- Makefile.PL, README, bin/lcfg-reltool, lcfg.yml, lib/LCFG/Build/VCS.pm,
  lib/LCFG/Build/VCS/CVS.pm: Improved the handling of the workdir attribute

* Mon Mar 03 2008 21:26  squinney
- lib/LCFG/Build/VCS/CVS.pm: Fixed switching to working directory

* Mon Mar 03 2008 21:04  squinney
- lib/LCFG/Build/VCS/CVS.pm: fixed switch to work directory

* Mon Mar 03 2008 20:57  squinney
- Changes, lcfg.yml: Release: 0.0.6

* Mon Mar 03 2008 20:57  squinney
- Build.PL, META.yml, Makefile.PL, README, bin/lcfg-reltool,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm, mk/release.mk,
  perl-LCFG-Build-VCS.spec: Added support for exporting CVS modules

* Thu Feb 28 2008 09:55  squinney
- Changes: Added Changes file to CVS

* Thu Feb 28 2008 09:54  squinney
- META.yml, README, lcfg.yml, lib/LCFG/Build/VCS.pm,
  lib/LCFG/Build/VCS/CVS.pm: Release: 0.0.5

* Thu Feb 28 2008 09:53  squinney
- Build.PL, MANIFEST, mk, mk/release.mk, perl-LCFG-Build-VCS.spec: Added
  simple release.mk so it is easy to use lcfg-reltool with make

* Wed Feb 20 2008 15:32  squinney
- MANIFEST, perl-LCFG-Build-VCS.spec: Added Changes file

* Wed Feb 20 2008 15:32  squinney
- Build.PL, MANIFEST, META.yml, Makefile.PL, README, lcfg.yml,
  lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec, t, t/01_load.t: Release: 0.0.4

* Wed Feb 20 2008 15:28  squinney
- lib/LCFG/Build/VCS/CVS.pm: Added basic documentation to
  LCFG::Build::VCS::CVS

* Wed Feb 20 2008 15:28  squinney
- lib/LCFG/Build/VCS.pm: Fixed small pod error

* Wed Feb 20 2008 15:27  squinney
- bin/lcfg-reltool: Improved control over the changelog filename from
  lcfg-reltool

* Wed Feb 20 2008 15:27  squinney
- lcfg.yml: Noted that we are using CVS

* Wed Feb 20 2008 15:26  squinney
- Build.PL: Added dependency on Date::Format

* Wed Feb 20 2008 15:03  squinney
- lib/LCFG/Build/VCS.pm: Added documentation

* Tue Feb 19 2008 17:22  squinney
- Build.PL, MANIFEST, MANIFEST.SKIP, META.yml, Makefile.PL, README, bin,
  bin/lcfg-reltool, lcfg.yml, lib, lib/LCFG, lib/LCFG/Build,
  lib/LCFG/Build/VCS, lib/LCFG/Build/VCS.pm, lib/LCFG/Build/VCS/CVS.pm,
  perl-LCFG-Build-VCS.spec: First release of LCFG::Build::VCS

* Tue Feb 19 2008 17:22  
- .: Standard project directories initialized by cvs2svn.


