Name:           perl-LCFG-Build-PkgSpec
Version:        0.2.7
Release:        1
Summary:        Object-oriented interface to LCFG build metadata
License:        GPLv2
Group:          Development/Libraries
Source0:        LCFG-Build-PkgSpec-0.2.7.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl >= 1:5.6.1
BuildRequires:  perl(Data::Structure::Util) >= 0.12
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Moose) >= 0.98
BuildRequires:  perl(Test::Differences)
BuildRequires:  perl(Test::Exception)
BuildRequires:  perl(YAML::Syck) >= 0.98
BuildRequires:  perl(DateTime)
BuildRequires:  perl(Email::Address), perl(Email::Valid)
Requires:       perl(Data::Structure::Util) >= 0.12
Requires:       perl(Moose) >= 0.98
Requires:       perl(YAML::Syck) >= 0.98
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
This class provides an object-oriented interface to the LCFG build
tools metadata file. All simple fields are available through attribute
accessors. Specific methods are also provided for querying and
modifying the more complex data types (e.g. lists and hashes).

This class has methods for carrying out specific procedures related to
tagging releases with the LCFG build tools. It also has methods for
handling the old format LCFG build configuration files.

More information on the LCFG build tools is available from the website
http://www.lcfg.org/doc/buildtools/

%prep
%setup -q -n LCFG-Build-PkgSpec-%{version}

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
/usr/bin/lcfg-cfg2meta
/usr/bin/lcfg-pkgcfg
%{perl_vendorlib}/LCFG/Build/PkgSpec.pm
%{_mandir}/man1/*
%{_mandir}/man3/*

%changelog
* Fri Mar 22 2019 SVN: new release
- Release: 0.2.7

* Fri Mar 22 2019 15:28  squinney@INF.ED.AC.UK
- debian/control: Need to build-depend on libmodule-build-perl

* Thu Mar 21 2019 16:36  squinney@INF.ED.AC.UK
- README: Added notes about what packages are required on Debian

* Fri Jan 18 2019 10:45  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.6

* Fri Jan 18 2019 10:45  squinney@INF.ED.AC.UK
- lcfg.yml, t/02_pkgspec_basic.t: updated tests for change to tarname
  accessor behaviour

* Fri Jan 18 2019 10:43  squinney@INF.ED.AC.UK
- lib/LCFG/Build/PkgSpec.pm.in: Need to keep the original tar file name for
  compatibility. Will instead symlink the Debian name to the real file

* Fri Jan 18 2019 09:51  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.5

* Fri Jan 18 2019 09:50  squinney@INF.ED.AC.UK
- Makefile.PL: Updated minimum perl version to 5.10

* Fri Jan 18 2019 09:49  squinney@INF.ED.AC.UK
- META.yml.in: quote version strings to be safer

* Fri Jan 18 2019 09:45  squinney@INF.ED.AC.UK
- Build.PL.in, META.json.in, META.yml.in, README: Updated minimum perl
  version to 5.10. Other minor metadata updates

* Fri Jan 18 2019 09:39  squinney@INF.ED.AC.UK
- Makefile.PL: minor tweak for latest Module::Build

* Fri Jan 18 2019 09:39  squinney@INF.ED.AC.UK
- debian/control: Added perl modules to build deps so tests can be run

* Wed Jan 16 2019 16:31  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.4

* Wed Jan 16 2019 16:31  squinney@INF.ED.AC.UK
- debian/control: changed debian binary package name to be
  'liblcfg-build-pkgspec-perl' so that it is more standard

* Tue Jan 15 2019 16:23  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.3

* Tue Jan 15 2019 16:22  squinney@INF.ED.AC.UK
- debian/changelog: Fixed email address in changelog

* Tue Jan 15 2019 16:21  squinney@INF.ED.AC.UK
- lib/LCFG/Build/PkgSpec.pm.in: Fixed POD errors

* Tue Jan 15 2019 16:19  squinney@INF.ED.AC.UK
- bin/lcfg-pkgcfg.in: Fixed POD errors

* Tue Jan 15 2019 16:11  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.2

* Tue Jan 15 2019 16:11  squinney@INF.ED.AC.UK
- debian, debian/compat, debian/control, debian/copyright, debian/docs,
  debian/rules, debian/source, debian/source/format, lcfg.yml, t/01_load.t,
  t/03_pkgspec_from_file.t, t/04_pkgspec_badattr.t, t/05_pkgspec_version.t,
  t/06_pkgspec_cfg.t, t/07_pkgspec_savemeta.t, t/08_pkgspec_cfg2.t,
  t/09_clone.t: Added debian packaging metadata

* Wed Jan 09 2019 12:54  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.1

* Wed Jan 09 2019 12:54  squinney@INF.ED.AC.UK
- lib/LCFG/Build/PkgSpec.pm.in: Added deb_dscname method to make it easy to
  get the name of the .dsc file for a project build

* Fri Dec 07 2018 15:59  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.2.0

* Fri Dec 07 2018 15:59  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm.in, t/05_pkgspec_version.t: Added
  various methods related to debian package names and versions. Altered the
  behaviour of dev_version so that it appends .dev and the release number

* Fri Dec 07 2018 13:07  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.1.3

* Fri Dec 07 2018 12:11  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm.in: Added a 'debname' method which
  can be used to get a name for the project which can be safely used for a
  debian package

* Fri Dec 07 2018 11:54  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.1.2

* Fri Dec 07 2018 11:53  squinney@INF.ED.AC.UK
- lcfg.yml, t/02_pkgspec_basic.t: Updated tests to check new support for
  alternate compression in tarname method

* Fri Dec 07 2018 11:49  squinney@INF.ED.AC.UK
- lib/LCFG/Build/PkgSpec.pm.in: Made it possible to alter the compression
  type for the tar file name

* Fri Dec 07 2018 10:14  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.1.1

* Fri Dec 07 2018 10:14  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm.in, t/02_pkgspec_basic.t: Minor tweak
  to the way the source tar.gz file name is built

* Wed Jun 24 2015 10:11  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.1.0

* Wed Jun 24 2015 10:11  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm.in: added a new 'perl_version' method
  which returns a version string which is always safe for use in perl
  modules

* Tue Jan 22 2013 14:20  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.36

* Tue Jan 22 2013 14:19  squinney@INF.ED.AC.UK
- bin/lcfg-pkgcfg.in: Reworked the get code some more so that lookups for
  unsupported attributes give a different error code. Also tidied the code
  slightly to appease perlcritic

* Tue Jan 22 2013 12:03  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.35

* Tue Jan 22 2013 12:03  squinney@INF.ED.AC.UK
- bin/lcfg-pkgcfg.in, lcfg.yml: Added support for accessing values stored
  in hashes

* Mon Apr 30 2012 13:49  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.34

* Mon Apr 30 2012 13:49  squinney@INF.ED.AC.UK
- lcfg.yml, t/expected.yml: Updated test for new attribute

* Mon Apr 30 2012 13:47  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.33

* Mon Apr 30 2012 13:47  squinney@INF.ED.AC.UK
- bin/lcfg-pkgcfg.in, lib/LCFG/Build/PkgSpec.pm.in: Added new orgident
  attribute and pkgident method. These are used for MacOSX packaging

* Mon Feb 14 2011 17:05  squinney@INF.ED.AC.UK
- README: updated README

* Mon Feb 14 2011 16:57  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.32

* Mon Feb 14 2011 16:57  squinney@INF.ED.AC.UK
- LCFG-Build-PkgSpec.spec: Fixed build-requires for new Email::Address and
  Email::Valid dependencies

* Mon Feb 14 2011 16:52  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.31

* Mon Feb 14 2011 16:45  squinney@INF.ED.AC.UK
- Build.PL.in, META.yml.in, Makefile.PL, lib/LCFG/Build/PkgSpec.pm.in,
  t/06_pkgspec_cfg.t: Switched to using Native Traits so we can drop the
  dependency on the deprecated AttributeHelpers module. Switched the email
  address list handling for the authors field to Email::Address &
  Email::Valid (new deps)

* Mon Feb 14 2011 16:41  squinney@INF.ED.AC.UK
- Build.PL.in, MANIFEST, META.yml.in, Makefile.PL: Updated dependency list,
  meta-data and build scripts

* Mon Feb 14 2011 15:55  squinney@INF.ED.AC.UK
- t/10_pkgspec_date.t: fixed date spec tests so they always work

* Fri Nov 19 2010 10:43  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.30

* Fri Nov 19 2010 10:43  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm.in, t/10_pkgspec_date.t: Fixed the
  date formatting so that it is DD/MM/YY and not the American style of
  MM/DD/YY. Also added tests so this does not happen again

* Fri Mar 13 2009 15:14  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-PkgSpec release: 0.0.29

* Fri Mar 13 2009 14:53  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-PkgSpec.spec, META.yml.in, Makefile.PL, README,
  lib/LCFG/Build/PkgSpec.pm.in: Switched from Date::Format to DateTime

* Wed Mar 11 2009 13:25  squinney@INF.ED.AC.UK
- bin/lcfg-cfg2meta.in, bin/lcfg-pkgcfg.in, lib/LCFG/Build/PkgSpec.pm.in:
  Set svn:keywords on the LCFG::Build::PkgSpec Perl modules and scripts

* Mon Mar 09 2009 16:43  squinney
- lcfg.yml: Removed hardwired version-control type from lcfg.yml to allow
  future transfer to subversion

* Mon Mar 09 2009 12:44  squinney
- Changes, lcfg.yml: Release: 0.0.28

* Mon Mar 09 2009 12:44  squinney
- lcfg.yml, t/06_pkgspec_cfg.t: Updated tests in 06_pkgspec_cfg.t to
  reflect the fact that we no longer hardwire the version-control system
  type

* Mon Mar 09 2009 12:42  squinney
- Changes, lcfg.yml: Release: 0.0.27

* Mon Mar 09 2009 12:42  squinney
- lib/LCFG/Build/PkgSpec.pm.in: lib/LCFG/Build/PkgSpec.pm.in
  (new_from_cfgmk): No longer hardwire the version-control system type to
  be CVS when converting config.mk files

* Wed Nov 12 2008 14:26  squinney
- Changes, lcfg.yml: Release: 0.0.26

* Wed Nov 12 2008 14:26  squinney
- t/09_clone.t: Switched to using is_deeply() in 09_clone.t test. The
  eq_or_diff() method in Test::Differences does not handle comparing an
  integer with a string (e.g. 1 is considered to not equal '1'. See
  http://rt.cpan.org/Public/Bug/Display.html?id=3029

* Wed Nov 12 2008 14:24  squinney
- lib/LCFG/Build/PkgSpec.pm.in: The schema is now explicitly an integer.

* Wed Oct 29 2008 14:24  squinney
- Changes, lcfg.yml: Release: 0.0.25

* Wed Oct 29 2008 14:24  squinney
- lib/LCFG/Build/PkgSpec.pm.in: Fixed a small problem with parsing the NAME
  field in a config.mk file

* Fri Sep 12 2008 14:28  squinney
- Changes, lcfg.yml: Release: 0.0.24

* Fri Sep 12 2008 14:28  squinney
- bin/lcfg-cfg2meta.in, bin/lcfg-pkgcfg.in: Switched file path handling in
  lcfg-cfg2meta and lcfg-pkgcfg to using File::Spec

* Wed Sep 10 2008 13:59  squinney
- bin/lcfg-pkgcfg.in, lib/LCFG/Build/PkgSpec.pm.in: Small documentation
  tweaks to get links to other modules automatically generated

* Tue Sep 09 2008 14:30  squinney
- Changes, lcfg.yml: Release: 0.0.23

* Tue Sep 09 2008 14:29  squinney
- Build.PL.in, LCFG-Build-PkgSpec.spec, META.yml, META.yml.in, Makefile.PL,
  README, bin/lcfg-cfg2meta.in, bin/lcfg-pkgcfg.in, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm.in, t/04_pkgspec_badattr.t: Support fields in
  config.mk which use the ling-continuation backslash. Improved handling of
  attributes which can be either strings or array-refs so that they get
  properly transformed into array-refs. Removed the override of the new()
  method as it is no longer required. Made the LCFG::Build::PkgSpec class
  immutable to get a speed gain. Improved the README and other docs.
  Updated various Moose dependencies to ensure the code works correctly

* Wed Jul 23 2008 10:56  squinney
- Changes, lcfg.yml: Release: 0.0.22

* Wed Jul 23 2008 10:56  squinney
- bin/lcfg-cfg2meta.in: If not specified search the current working
  directory for the config.mk when using lcfg-cfg2meta

* Tue Jul 01 2008 14:37  squinney
- Changes, lcfg.yml: Release: 0.0.21

* Tue Jul 01 2008 14:36  squinney
- t/06_pkgspec_cfg.t: Updated the tests which go with the config.mk parser

* Tue Jul 01 2008 14:32  squinney
- Changes, lcfg.yml: Release: 0.0.20

* Tue Jul 01 2008 14:32  squinney
- lib/LCFG/Build/PkgSpec.pm.in: When parsing a config.mk make the default
  license GPLv2 to be redhat compatible, also removed the specfile from the
  translate list and turned on the gencmake option

* Tue Jul 01 2008 10:37  squinney
- Build.PL.in, Changes, lcfg.yml: Release: 0.0.19

* Tue Jul 01 2008 10:37  squinney
- LCFG-Build-PkgSpec.spec: Modified specfile to avoid installing
- .in files

* Tue Jul 01 2008 08:53  squinney
- Changes, lcfg.yml: Release: 0.0.18

* Tue Jul 01 2008 08:51  squinney
- LCFG-Build-PkgSpec.spec, lcfg.yml: Increased dependency on Moose to 0.51
  to get consistent error messages

* Tue Jul 01 2008 08:51  squinney
- Build.PL, Build.PL.in, bin/lcfg-cfg2meta, bin/lcfg-cfg2meta.in,
  bin/lcfg-pkgcfg, bin/lcfg-pkgcfg.in, lib/LCFG/Build/PkgSpec.pm,
  lib/LCFG/Build/PkgSpec.pm.in: Moved to *.in files for perl libraries and
  executables

* Tue Jul 01 2008 08:34  squinney
- Build.PL, Changes, LCFG-Build-PkgSpec.spec, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm, t/05_pkgspec_version.t: Release: 0.0.17

* Thu Jun 05 2008 14:04  squinney
- Changes, lcfg.yml: Release: 0.0.16

* Thu Jun 05 2008 14:03  squinney
- Build.PL, LCFG-Build-PkgSpec.spec, MANIFEST, META.yml, Makefile.PL,
  README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm, t/09_clone.t: Added clone method to
  LCFG::Build::PkgSpec and accompanying tests

* Wed Jun 04 2008 15:35  squinney
- perl-LCFG-Build-PkgSpec.spec: renamed perl-LCFG-Build-PkgSpec.spec to
  LCFG-Build-PkgSpec.spec

* Wed Jun 04 2008 14:01  squinney
- META.yml, Makefile.PL, README: updated metadata files

* Wed Jun 04 2008 14:00  squinney
- Changes, lcfg.yml: Release: 0.0.15

* Wed Jun 04 2008 14:00  squinney
- Build.PL, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lib/LCFG/Build/PkgSpec.pm,
  perl-LCFG-Build-PkgSpec.spec: made build info attribute lazy

* Wed Jun 04 2008 13:47  squinney
- META.yml, README: updated meta files

* Wed Jun 04 2008 13:47  squinney
- Build.PL, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lib/LCFG/Build/PkgSpec.pm,
  perl-LCFG-Build-PkgSpec.spec: updated version string everywhere

* Wed Jun 04 2008 13:43  squinney
- Changes, lcfg.yml: Release: 0.0.14

* Wed Jun 04 2008 13:37  squinney
- lcfg.yml, lib/LCFG/Build/PkgSpec.pm: Added build info section support for
  lcfg metadata file

* Tue Jun 03 2008 12:40  squinney
- Changes, lcfg.yml: Release: 0.0.13

* Tue Jun 03 2008 12:17  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec,
  t/05_pkgspec_version.t: Added dev_version and update_release methods

* Wed May 28 2008 11:29  squinney
- Changes, lcfg.yml: Release: 0.0.12

* Wed May 28 2008 11:27  squinney
- Build.PL, META.yml, Makefile.PL, README, bin/lcfg-cfg2meta,
  bin/lcfg-pkgcfg, lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec:
  *** empty log message ***

* Wed May 28 2008 11:24  squinney
- Build.PL, perl-LCFG-Build-PkgSpec.spec: Updated dependencies on Moose and
  MooseX::AttributeHelpers

* Wed May 28 2008 11:17  squinney
- perl-LCFG-Build-PkgSpec.spec: updated specfile

* Wed May 28 2008 11:16  squinney
- Changes, lcfg.yml: Release: 0.0.11

* Wed May 28 2008 11:15  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg,
  lib/LCFG/Build/PkgSpec.pm, t/05_pkgspec_version.t: Renamed the smallest
  part of the version from 'level' to 'micro'. Added ability to query the
  individual parts of the version. Added an attribute to store the metafile
  name which can be used as a default when saving out the changed spec

* Wed May 07 2008 10:46  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec: version is now
  0.0.10

* Wed May 07 2008 10:45  squinney
- Changes, lcfg.yml: Release: 0.0.10

* Wed May 07 2008 10:45  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec,
  t/02_pkgspec_basic.t: Added new tarname() method and associated tests and
  docs

* Wed Apr 30 2008 14:29  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec,
  t/02_pkgspec_basic.t, t/03_pkgspec_from_file.t, t/06_pkgspec_cfg.t: Added
  fullname method

* Thu Mar 06 2008 09:45  squinney
- Build.PL, Changes, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg,
  lcfg.yml, lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec:
  Release: 0.0.7

* Thu Mar 06 2008 09:40  squinney
- lib/LCFG/Build/PkgSpec.pm, t/05_pkgspec_version.t: Added support for dev
  versions

* Tue Mar 04 2008 10:06  squinney
- Changes, lcfg.yml: Release: 0.0.6

* Tue Mar 04 2008 10:06  squinney
- Build.PL, META.yml, README, bin/lcfg-cfg2meta, bin/lcfg-pkgcfg,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec: Added support
  for setting a list of files to translate @FOO@ macros

* Mon Mar 03 2008 12:09  squinney
- Changes, lcfg.yml: Release: 0.0.5

* Mon Mar 03 2008 12:08  squinney
- Build.PL, META.yml, Makefile.PL, README, bin/lcfg-cfg2meta,
  bin/lcfg-pkgcfg, lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec:
  new release number

* Mon Mar 03 2008 12:02  squinney
- lib/LCFG/Build/PkgSpec.pm, t/04_pkgspec_badattr.t: Improved error message
  when creating a new pkgspec object and a required parameter is missing

* Mon Mar 03 2008 11:57  squinney
- Build.PL, META.yml, Makefile.PL, lib/LCFG/Build/PkgSpec.pm,
  t/05_pkgspec_version.t: Minimum version for Moose is now 0.38. This
  allows the setting of the release field as either undef or a validated
  string through the Maybe[] type syntax. Various tests were also updated
  as the error strings had changed slightly.

* Thu Feb 28 2008 12:09  squinney
- Changes, lcfg.yml: Release: 0.0.4

* Thu Feb 28 2008 12:08  squinney
- Build.PL, META.yml, README, bin/lcfg-pkgcfg, lcfg.yml,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec: Updated version

* Thu Feb 28 2008 12:08  squinney
- bin/lcfg-cfg2meta: Added new --set, --skeleton options to lcfg-pkgcfg.
  Also added the ability to clone metadata files.

* Wed Feb 20 2008 14:03  squinney
- Changes, lcfg.yml: Release: 0.0.3

* Wed Feb 20 2008 14:02  squinney
- MANIFEST, META.yml, Makefile.PL, README, bin/lcfg-cfg2meta,
  bin/lcfg-pkgcfg, lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec:
  Set version to 0.0.3

* Wed Feb 20 2008 14:02  squinney
- Build.PL: Added dependency on Date::Format

* Wed Feb 20 2008 13:52  squinney
- Changes, lcfg.yml, perl-LCFG-Build-PkgSpec.spec: Release: 0.0.2

* Wed Feb 20 2008 13:51  squinney
- lcfg.yml: Added version control information to lcfg.yml

* Wed Feb 20 2008 13:49  squinney
- t/03_pkgspec_from_file.t, t/05_pkgspec_version.t, t/06_pkgspec_cfg.t,
  t/08_pkgspec_cfg2.t, t/expected.yml, t/lcfg.yml: updated tests to deal
  with the new date attribute handling

* Wed Feb 20 2008 13:47  squinney
- lib/LCFG/Build/PkgSpec.pm: Improved date handling, it now defaults to
  'DD/MM/YY HH:MM:SS'. Added update_date() method and made the
  update_major, update_minor and update_level methods use it

* Wed Feb 20 2008 13:45  squinney
- Changes: Added Changes file

* Tue Feb 19 2008 16:58  squinney
- lcfg.yml: Added lcfg.yml

* Tue Feb 19 2008 16:38  squinney
- Build.PL, MANIFEST, MANIFEST.SKIP, META.yml, Makefile.PL, README, bin,
  bin/lcfg-cfg2meta, bin/lcfg-pkgcfg, lib, lib/LCFG, lib/LCFG/Build,
  lib/LCFG/Build/PkgSpec.pm, perl-LCFG-Build-PkgSpec.spec, t, t/01_load.t,
  t/02_pkgspec_basic.t, t/03_pkgspec_from_file.t, t/04_pkgspec_badattr.t,
  t/05_pkgspec_version.t, t/06_pkgspec_cfg.t, t/07_pkgspec_savemeta.t,
  t/08_pkgspec_cfg2.t, t/config.mk, t/config2.mk, t/expected.yml,
  t/lcfg.yml: First release of LCFG::Build::PkgSpec

* Tue Feb 19 2008 16:38  
- .: Standard project directories initialized by cvs2svn.


