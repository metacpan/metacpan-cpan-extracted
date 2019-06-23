Name:           perl-LCFG-Build-Tools
Version:        0.9.30
Release:        1
Summary:        LCFG build system tools
License:        gpl
Group:          Development/Libraries
Source0:        LCFG-Build-Tools-0.9.30.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl >= 5.16.0
BuildRequires:  perl(LCFG::Build::PkgSpec) >= 0.2.6
BuildRequires:  perl(LCFG::Build::VCS) >= 0.3.7
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(Module::Pluggable)
BuildRequires:  perl(File::HomeDir) >= 0.58
BuildRequires:  perl(YAML::Syck) >= 0.98
BuildRequires:  perl(File::Find::Rule), perl(File::pushd)
BuildRequires:  perl(Template) >= 2.14
BuildRequires:  perl(Archive::Tar), perl(IO::Zlib)
BuildRequires:  perl(MooseX::App::Cmd) >= 0.06
BuildRequires:  perl(UNIVERSAL::require)
BuildRequires:  perl(Test::Differences), perl(Test::More), perl(Test::Exception)
BuildRequires:  perl(DateTime), perl(Readonly)
Requires:       perl(LCFG::Build::PkgSpec) >= 0.2.6
Requires:       perl(LCFG::Build::VCS) >= 0.3.7
Requires:       perl(YAML::Syck) >= 0.98
Requires:       perl(File::Find::Rule)
Requires:       perl(Template) >= 2.14
Requires:       perl(Archive::Tar), perl(IO::Zlib)
Requires:       perl(MooseX::App::Cmd) >= 0.06
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
LCFG::Build::Tools is a suite of tools designed to handle the
releasing of LCFG software projects and the creation of
packages. Support is available for developing projects within a
version-control systems (currently either CVS or None). By default a
source tar file is generated along with a specfile for building binary
RPMs. Support is provided for building binary RPMs directly. Work is
under way to also fully support the generation of MacOSX packages.

Although this software is designed for managing LCFG projects there is
nothing that requires the software be for LCFG. All the tools included
are designed to more widely applicable.

This suite has been intentionally designed to be easy to extend to
support new version-control systems (e.g. subversion, git, etc) and
new package formats (e.g. for Debian). It has also been designed to
ensure that it is easy to extend with additional command modules. For
further details see the online documentation at
http://www.lcfg.org/doc/buildtools/

%prep
%setup -q -n LCFG-Build-Tools-%{version}

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
%doc Changes
%doc %{_mandir}/man1/*
%doc %{_mandir}/man3/*
%{perl_vendorlib}/LCFG/Build/Tool/*.pm
%{perl_vendorlib}/LCFG/Build/Tool.pm
%{perl_vendorlib}/LCFG/Build/Tools.pm
%{perl_vendorlib}/LCFG/Build/Utils.pm
%{perl_vendorlib}/LCFG/Build/Utils/*.pm
/usr/share/lcfgbuild/
/usr/bin/lcfg-reltool

%changelog
* Fri Jun 21 2019 SVN: new release
- Release: 0.9.30

* Fri Jun 21 2019 09:28  squinney@INF.ED.AC.UK
- lcfg.yml, templates/debian/COMP-nagios.install,
  templates/debian/COMP-nagios.manpages: list of default files for nagios
  sub-package

* Fri Jun 21 2019 09:28  squinney@INF.ED.AC.UK
- templates/debian/control: don't depend on perl if not a perl component

* Fri Jun 21 2019 09:27  squinney@INF.ED.AC.UK
- templates/debian/COMP.manpages: Only include manpages from section 8 by
  default

* Fri Jun 21 2019 09:27  squinney@INF.ED.AC.UK
- templates/debian/COMP.install: only include perl modules for components
  by default

* Fri Jun 21 2019 09:27  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Need Try::Tiny

* Fri Jun 21 2019 08:50  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/GenDeb.pm.in: fixed logic for nagios module
  check

* Fri Jun 21 2019 08:48  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in, templates/debian/COMP-nagios.install,
  templates/debian/control: Added support for nagios sub-package for
  components

* Thu Jun 20 2019 09:54  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.29

* Thu Jun 20 2019 09:54  squinney@INF.ED.AC.UK
- debian/docs, debian/rules, lcfg.yml: Fixed installation of changelog

* Thu Jun 20 2019 09:52  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.28

* Wed Jun 19 2019 19:17  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Handle changelog with
  dh_installchangelogs rather than dh_install

* Wed Jun 19 2019 19:17  squinney@INF.ED.AC.UK
- templates/debian/rules: Ensure upstream changelog is always installed
  correctly

* Wed Apr 17 2019 08:29  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.27

* Tue Apr 16 2019 09:06  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Removed debug message I didn't intend to include

* Tue Apr 16 2019 09:04  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Handle case of distribution release version not
  having a minor part (e.g. Centos), closes:
  https://bugs.lcfg.org/show_bug.cgi?id=1129

* Fri Mar 22 2019 16:03  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.26

* Fri Mar 22 2019 16:03  squinney@INF.ED.AC.UK
- debian/control, lcfg.yml: Need to build-depend on libmodule-build-perl

* Thu Mar 21 2019 17:16  squinney@INF.ED.AC.UK
- debian/control: Added missing dependency on libmoosex-app-cmd-perl

* Thu Mar 14 2019 15:58  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.25

* Thu Mar 14 2019 15:16  squinney@INF.ED.AC.UK
- templates/debian/COMP.lintian-overrides: Added lintian override to
  explain that the systemd service for a component is typically associated
  with lcfg-multi-user.target

* Thu Mar 14 2019 15:15  squinney@INF.ED.AC.UK
- templates/debian/COMP.service: Added StandardOutput setting to send
  output to console, very useful for boot time to see progress

* Thu Mar 14 2019 10:10  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.24

* Thu Mar 14 2019 10:09  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Improved comment about COMP template
  handling

* Thu Mar 14 2019 10:05  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/GenDeb.pm.in,
  templates/debian/COMP-doc.install, templates/debian/DEB_NAME-doc.install,
  templates/debian/control: Create doc sub-package by default for all
  projects, not just components

* Thu Mar 14 2019 10:04  squinney@INF.ED.AC.UK
- templates/debian/COMP.install: Added support for perl-based components
  which ship with modules

* Thu Mar 14 2019 10:03  squinney@INF.ED.AC.UK
- mapping_config.yml: Map macros for the deb_* methods

* Wed Mar 13 2019 11:07  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Added test to see if the component
  looks like it has a perl library

* Wed Mar 13 2019 11:00  squinney@INF.ED.AC.UK
- templates/debian/rules: Improved comments on optional sections

* Wed Mar 13 2019 11:00  squinney@INF.ED.AC.UK
- templates/debian/control: Improved generated descriptions to make lintian
  happier

* Wed Mar 13 2019 07:45  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/GenDeb.pm.in,
  templates/debian/COMP-defaults.install,
  templates/debian/COMP-doc.install, templates/debian/COMP.install,
  templates/debian/COMP.manpages, templates/debian/COMP.postinst,
  templates/debian/COMP.postrm, templates/debian/COMP.prerm,
  templates/debian/COMP.service, templates/debian/control,
  templates/debian/postinst, templates/debian/postrm,
  templates/debian/prerm, templates/debian/service: Reworked the way the
  debian package templates work for components. Now results in 3 packages -
  main, docs and defaults

* Wed Mar 06 2019 14:15  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.23

* Wed Mar 06 2019 14:15  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: marked component script as optional as
  'virtual' components do not have any code, just a schema

* Thu Feb 28 2019 18:46  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.22

* Thu Feb 28 2019 18:45  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Properly fixed pod_strip so that the code is
  only run when the podselect tool is available

* Thu Feb 28 2019 16:50  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.21

* Thu Feb 28 2019 16:50  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Altered the behaviour of pod_strip so that it
  removes empty output files generated with podselect when the input file
  does not contain any POD. Also modified lcfg_add_perl_module to not
  attempt to install pod/man files if pod_strip did not create a file

* Thu Feb 28 2019 10:04  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/CheckMacros.pm.in: Included LCFG_PERL_VERSION in list
  of standard macros

* Mon Feb 18 2019 09:35  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.20

* Mon Feb 18 2019 09:34  squinney@INF.ED.AC.UK
- Makefile.PL: Fixed missing comma in prereq list of packages, closes:
  https://rt.cpan.org/Public/Bug/Display.html?id=128543

* Thu Jan 24 2019 10:50  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.19

* Thu Jan 24 2019 10:39  squinney@INF.ED.AC.UK
- lcfg.yml, templates/build.cmake.tt: Fixed the pod to man page convertor,
  closes: https://bugs.lcfg.org/show_bug.cgi?id=1110 Also reworked a number
  of other macros to take a better approach to searching for files in both
  source and binary directories

* Fri Jan 18 2019 15:20  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.18

* Fri Jan 18 2019 15:19  squinney@INF.ED.AC.UK
- debian/changelog: fixed broken email address

* Fri Jan 18 2019 15:19  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.17

* Fri Jan 18 2019 15:19  squinney@INF.ED.AC.UK
- debian/control: fixed missing comma in Build-Depends-Indep

* Fri Jan 18 2019 15:09  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.16

* Fri Jan 18 2019 15:09  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec: Need to build-depend on perl(File::pushd) for
  tests

* Fri Jan 18 2019 15:04  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.15

* Fri Jan 18 2019 15:04  squinney@INF.ED.AC.UK
- Build.PL.in, META.json.in, META.yml.in, Makefile.PL, README, lcfg.yml:
  various updates to deps lists and other project metadata

* Fri Jan 18 2019 15:04  squinney@INF.ED.AC.UK
- debian/control: Bumped dep on liblcfg-build-vcs-perl to 0.3.7, added dep
  on libfile-pushd-perl

* Fri Jan 18 2019 15:01  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec, lib/LCFG/Build/Tool.pm.in: bumped dep on
  LCFG::Build::PkgSpec to 0.2.6

* Fri Jan 18 2019 11:56  squinney@INF.ED.AC.UK
- Build.PL.in: updated deps

* Fri Jan 18 2019 11:56  squinney@INF.ED.AC.UK
- README: updated instructions

* Fri Jan 18 2019 11:51  squinney@INF.ED.AC.UK
- debian/control: Added all perl modules to build-deps so tests will run

* Fri Jan 18 2019 11:42  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Generate a symlink to the source tar
  file which has the correct name for Debian packages

* Thu Jan 17 2019 16:26  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.14

* Thu Jan 17 2019 16:22  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Fixed copying of build products back
  to the results directory

* Thu Jan 17 2019 16:14  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.13

* Thu Jan 17 2019 16:05  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Fixed working directory for
  generate_debtar. Fixed parsing of output from dpkg-source

* Thu Jan 17 2019 16:05  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils.pm.in: Improved switching between working
  directories in generate_srctar

* Thu Jan 17 2019 15:07  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.12

* Thu Jan 17 2019 15:06  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.json.in, META.yml.in,
  Makefile.PL, lcfg.yml: Require 0.3.7 or newer for LCFG::Build::VCS

* Thu Jan 17 2019 15:06  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Utils/Debian.pm.in:
  update debian/changelog for devel releases

* Wed Jan 16 2019 16:35  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.11

* Wed Jan 16 2019 16:35  squinney@INF.ED.AC.UK
- debian/control: Fixed names of lcfg build tools packages. Also recommend
  build-essential package

* Wed Jan 16 2019 16:25  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.10

* Wed Jan 16 2019 16:25  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DebianPkg.pm.in,
  lib/LCFG/Build/Tool/DevDebianPkg.pm.in: updated the docs

* Wed Jan 16 2019 16:21  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/RPM.pm.in: Set
  minimum perl version to 5.10

* Wed Jan 16 2019 16:07  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/DebianPkg.pm.in,
  lib/LCFG/Build/Tool/DevDebianPkg.pm.in, t/01_load.t: Added 'dev' version
  of debian package builder

* Wed Jan 16 2019 11:52  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils/Debian.pm.in: fixed incorrect variable
  name

* Wed Jan 16 2019 11:47  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Added support for sourceonly, nodeps
  and sign options

* Wed Jan 16 2019 11:38  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Added support for running debuild

* Wed Jan 16 2019 10:46  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/Debian.pm.in,
  lib/LCFG/Build/Tool/DebianPkg.pm.in, t/01_load.t: renamed module for
  clarity

* Wed Jan 16 2019 10:44  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/Debian.pm.in: Made a start on support for building
  debian packages

* Wed Jan 16 2019 10:42  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: Made a start on support for building
  debian packages

* Wed Jan 16 2019 09:55  squinney@INF.ED.AC.UK
- debian/control: Altered debian binary package name to match with standard
  perl module naming convention

* Tue Jan 15 2019 16:57  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.9

* Tue Jan 15 2019 16:55  squinney@INF.ED.AC.UK
- debian/changelog: Fixed errors in early entries

* Tue Jan 15 2019 16:54  squinney@INF.ED.AC.UK
- bin/lcfg-reltool.in: Fixed POD errors

* Tue Jan 15 2019 16:47  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.8

* Tue Jan 15 2019 16:47  squinney@INF.ED.AC.UK
- debian/control: Updated homepage

* Tue Jan 15 2019 16:46  squinney@INF.ED.AC.UK
- debian/control: Updated dependencies

* Tue Jan 15 2019 16:00  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.7

* Thu Jan 10 2019 16:21  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils/Debian.pm.in: Tweaked log messages

* Thu Jan 10 2019 15:31  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Utils.pm.in,
  lib/LCFG/Build/Utils/Debian.pm.in: Introduced a new way of calling
  methods on util plugins and added support for generate_metadata_post
  which is called after the source tar file is created

* Thu Jan 10 2019 14:48  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Utils/Debian.pm.in: Call generate_debtar from generate_dsc
  so that only a single subroutine needs to be called from a Tool module

* Thu Jan 10 2019 14:45  squinney@INF.ED.AC.UK
- templates/dsc.tt: No need to append release number to debian version,
  that now comes directly from the changelog

* Thu Jan 10 2019 14:38  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils/Debian.pm.in: forgot to declare $version

* Thu Jan 10 2019 14:36  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Utils/Debian.pm.in: Alternate approach to getting the
  debian package version which more closely matches the 'debian way'

* Thu Jan 10 2019 12:38  squinney@INF.ED.AC.UK
- templates/dsc.tt: Set the debian release to 1

* Thu Jan 10 2019 12:36  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Utils/Debian.pm.in, templates/dsc.tt: Pass in the package
  version when generating the debian dsc file

* Thu Jan 10 2019 12:22  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils/Debian.pm.in, templates/dsc.tt: Really
  make the field names look nicer

* Thu Jan 10 2019 12:05  squinney@INF.ED.AC.UK
- templates/dsc.tt: Tidy up case of field names

* Thu Jan 10 2019 12:02  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils/Debian.pm.in, templates/dsc.tt: Added
  support for the Package-List and Architecture dsc fields

* Thu Jan 10 2019 11:24  squinney@INF.ED.AC.UK
- debian/control: Added better description

* Thu Jan 10 2019 10:47  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/GenDeb.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/Debian.pm.in: Specified
  minimum required versions for some modules

* Thu Jan 10 2019 10:47  squinney@INF.ED.AC.UK
- t/01_load.t, t/02_macros.t: Added shebang so the test files look more
  like perl scripts

* Thu Jan 10 2019 10:46  squinney@INF.ED.AC.UK
- debian/control: Improved the list of dependencies and added versions for
  some modules. Also added build-dependencty on libtest-differences-perl

* Wed Jan 09 2019 18:38  squinney@INF.ED.AC.UK
- debian/control: Added list of dependencies

* Wed Jan 09 2019 16:28  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, Makefile.PL, README, lcfg.yml,
  lib/LCFG/Build/Tool.pm.in: Increased minimum dep on LCFG::Build::Pkgspec
  to 0.2.1 to get deb_dscname method

* Wed Jan 09 2019 16:28  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in, templates/dsc.tt: More work on
  generating the Debian dsc file

* Wed Jan 09 2019 13:03  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: made the generation of DSC files
  completely optional

* Wed Jan 09 2019 13:03  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in: Pass
  in required dsc filename

* Wed Jan 09 2019 12:29  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in: Use
  new Utils::Debian module for generating tar and dsc files

* Wed Jan 09 2019 12:28  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils.pm.in: Moved generate_debtar to new Utils::Debian
  module

* Wed Jan 09 2019 12:28  squinney@INF.ED.AC.UK
- templates/dsc.tt: Start of new template for Debian package .dsc file

* Wed Jan 09 2019 12:28  squinney@INF.ED.AC.UK
- t/01_load.t: Test new Utils::Debian module

* Wed Jan 09 2019 12:27  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/Debian.pm.in: New module for handling debian
  packaging work

* Wed Jan 09 2019 12:27  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec: Include all Utils modules

* Wed Jan 09 2019 10:39  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.6

* Wed Jan 09 2019 10:38  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/DevOSXPkg.pm.in,
  lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/OSXPkg.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Tool/RPM.pm.in, lib/LCFG/Build/Tool/Submit.pm.in:
  Introduced a new output_dir method which can be shared by all build tool
  modules.

* Wed Jan 09 2019 10:09  squinney@INF.ED.AC.UK
- debian/rules: Enabled svn:executable property

* Wed Jan 09 2019 10:09  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Ensure the debian/rules file is
  executable

* Tue Jan 08 2019 16:23  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Only attempt to install the templates directory
  if it exists

* Tue Jan 08 2019 15:58  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.5

* Tue Jan 08 2019 15:32  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Updated docs

* Tue Jan 08 2019 15:10  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Added final note asking developer to
  review the new debian directory

* Tue Jan 08 2019 15:09  squinney@INF.ED.AC.UK
- templates/debian/rules: Added override for dh_installsystemd to ensure
  that the component isn't enabled/started/stopped automatically by systemd
  when the package is changed. We will handle that directly ourselves

* Tue Jan 08 2019 15:01  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Add the 'debian' directory to the
  repository if it is new

* Tue Jan 08 2019 15:00  squinney@INF.ED.AC.UK
- templates/debian/control: further improvements to handling of dependency
  list

* Tue Jan 08 2019 14:54  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.4

* Tue Jan 08 2019 14:53  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Fixed handling of the logfile name so
  that it matches how the (micro,minor,major)version modules do things

* Tue Jan 08 2019 14:52  squinney@INF.ED.AC.UK
- templates/debian/control: Fixed handling of whitespace for end of
  dependency list

* Tue Jan 08 2019 14:51  squinney@INF.ED.AC.UK
- debian/docs: Added docs

* Tue Jan 08 2019 14:51  squinney@INF.ED.AC.UK
- debian/control: Fixed deps

* Tue Jan 08 2019 14:39  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.3

* Tue Jan 08 2019 14:39  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.json.in, META.yml.in,
  Makefile.PL, README: Set minimum dep on LCFG::Build::VCS to 0.3.3

* Tue Jan 08 2019 12:01  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in, templates/debian/service: Added support
  for generating a basic systemd service file for components

* Tue Jan 08 2019 11:54  squinney@INF.ED.AC.UK
- debian/rules: for clarity remove the CMake specific stuff

* Fri Jan 04 2019 17:25  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Fix permissions of debian scripts which
  should be executable

* Fri Jan 04 2019 16:41  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.2

* Fri Jan 04 2019 16:41  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Adjusted the location of some directories in
  /var for FHS support

* Fri Jan 04 2019 15:39  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.1

* Fri Jan 04 2019 15:38  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/GenDeb.pm.in: Identify docs files which should be
  included in the debian package

* Fri Jan 04 2019 15:13  squinney@INF.ED.AC.UK
- Changes, debian/changelog, lcfg.yml: LCFG-Build-Tools release: 0.9.0

* Fri Jan 04 2019 15:13  squinney@INF.ED.AC.UK
- Build.PL.in, lcfg.yml, lib/LCFG/Build/Tool/GenDeb.pm.in, t/01_load.t:
  Added tool to generate Debian metadata

* Fri Jan 04 2019 15:12  squinney@INF.ED.AC.UK
- templates/debian/control: Only add lcfg-om and lcfg-ngeneric for
  components

* Fri Jan 04 2019 15:12  squinney@INF.ED.AC.UK
- debian, debian/compat, debian/control, debian/copyright, debian/docs,
  debian/rules, debian/source, debian/source/format: First attempt at
  debian packaging

* Fri Jan 04 2019 14:27  squinney@INF.ED.AC.UK
- templates/debian/control: Fixed path to viewvc

* Fri Jan 04 2019 13:52  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec: include all files in lcfgbuild directory

* Fri Jan 04 2019 13:47  squinney@INF.ED.AC.UK
- templates/debian, templates/debian/compat, templates/debian/control,
  templates/debian/copyright, templates/debian/docs,
  templates/debian/postinst, templates/debian/postrm,
  templates/debian/prerm, templates/debian/rules, templates/debian/source,
  templates/debian/source/format: Debian package metadata file templates

* Fri Jan 04 2019 13:46  squinney@INF.ED.AC.UK
- Build.PL.in: Reworked how the template files are gathered so all sub-dirs
  are included

* Thu Jan 03 2019 14:14  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Improved logrotate and nagios macros to handle
  out-of-tree builds

* Thu Jan 03 2019 13:59  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Improved lcfg_add_templates to handle
  out-of-tree builds

* Thu Jan 03 2019 10:35  squinney@INF.ED.AC.UK
- lcfg.yml, templates/build.cmake.tt: Improved lcfg_add_pod so that it can
  handle out-of-tree builds

* Thu Jan 03 2019 10:09  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tools.pm.in: Fixed POD

* Tue Dec 18 2018 21:21  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Complete overhaul of how we handle the locations
  of LCFG files and directories to provide support for Debian

* Wed Dec 12 2018 15:11  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.8.0

* Wed Dec 12 2018 15:11  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.json.in, META.yml.in,
  Makefile.PL, README, lcfg.yml: Updated minimum required version for
  LCFG::Build::VCS to 0.3.1

* Wed Dec 12 2018 15:10  squinney@INF.ED.AC.UK
- bin/lcfg-reltool.in: use safe version macro

* Wed Dec 12 2018 15:10  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/MicroVersion.pm.in: Added support for updating the
  debian/changelog when required

* Fri Dec 07 2018 16:25  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.7.0

* Fri Dec 07 2018 16:25  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.json.in, META.yml.in,
  Makefile.PL, README, lcfg.yml, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Added basic
  support for building a debian source tar file

* Fri Dec 07 2018 11:38  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.9

* Fri Dec 07 2018 11:38  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils.pm.in: Do not include any top-level debian
  directory in the source tar file

* Mon Nov 20 2017 16:01  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.8

* Mon Nov 20 2017 16:01  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.json.in, META.yml.in,
  Makefile.PL, README, lcfg.yml: Updated minimum dep on LCFG::Build::VCS to
  0.2.5

* Mon Nov 20 2017 15:51  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.7

* Mon Nov 20 2017 15:51  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MicroVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in: Added support for storing the
  project version string in a text file when a micro, minor or major
  version is tagged

* Mon Nov 20 2017 14:36  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/MicroVersion.pm.in: Added support for storing build
  id string into text file in project directory

* Tue Jul 12 2016 12:59  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.6

* Tue Jul 12 2016 12:58  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Fixed lcfg_add_perl_tree and
  lcfg_add_perl_module to handle cmake binary and source directories being
  different

* Tue Jul 12 2016 12:17  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Some more tweaking of cmake macros to support
  having a BINARY_DIR which is different from the SOURCE_DIR

* Fri Jun 10 2016 15:34  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.5

* Fri Jun 10 2016 15:34  squinney@INF.ED.AC.UK
- lcfg.yml, templates/build.cmake.tt: Fixed call to lcfg_add_man in
  lcfg_pod2man so that it works correctly when the binary and source
  directories are not the same place

* Sat Nov 14 2015 15:28  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.4

* Sat Nov 14 2015 15:28  squinney@INF.ED.AC.UK
- lcfg.yml, t/02_macros.t: fixed test

* Sat Nov 14 2015 15:04  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.3

* Sat Nov 14 2015 15:03  squinney@INF.ED.AC.UK
- META.json.in, META.yml.in, lcfg.yml: Tweaked metadata so that it will be
  indexed on cpan

* Thu Nov 12 2015 10:13  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.2

* Thu Nov 12 2015 10:11  squinney@INF.ED.AC.UK
- Build.PL.in, META.json.in, META.yml.in, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MicroVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/SRPM.pm.in, lib/LCFG/Build/Tool/Submit.pm.in,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils.pm.in,
  lib/LCFG/Build/Utils/OSXPkg.pm.in, lib/LCFG/Build/Utils/RPM.pm.in:
  Replaced LCFG_VERSION with LCFG_PERL_VERSION in perl modules to ensure
  the version string is always safe

* Thu Nov 12 2015 10:05  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Set CMAKE_INSTALL_NAME_DIR to /usr/local/lib for
  MacOSX, closes https://bugs.lcfg.org/show_bug.cgi?id=911

* Fri Nov 06 2015 16:03  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.1

* Fri Nov 06 2015 16:02  squinney@INF.ED.AC.UK
- Build.PL.in, lcfg.yml, lcfg_config_osx.yml: Added a different
  lcfg_config.yml file for use on MacOSX where all paths should be in
  /usr/local

* Fri Nov 06 2015 15:22  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Dropped hardwiring of the INSTALL_PREFIX to be
  /usr for Darwin

* Fri Nov 06 2015 15:21  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/OSXPkg.pm.in: Dropped the full paths for cmake, make
  and pkgbuild, just rely on them being found somewhere in the PATH

* Fri Nov 06 2015 15:08  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.6.0

* Fri Nov 06 2015 15:07  squinney@INF.ED.AC.UK
- Build.PL.in, bin/lcfg-reltool.in, lcfg.yml, lib/LCFG/Build/Tools.pm.in,
  lib/LCFG/Build/Utils.pm.in, t/02_macros.t: Altered LCFG::Build::Utils to
  check in both /usr/local/share/lcfgbuild and /usr/share/lcfgbuild for the
  necessary templates and data files. This means that the tools should now
  work on the latest MacOSX. See https://bugs.lcfg.org/show_bug.cgi?id=907
  for details.

* Wed Jun 24 2015 10:32  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.5.1

* Wed Jun 24 2015 10:32  squinney@INF.ED.AC.UK
- Build.PL.in, META.json.in, META.yml.in: reduced dependency on
  Module::Build to 0.38

* Wed Jun 24 2015 10:23  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.5.0

* Wed Jun 24 2015 10:21  squinney@INF.ED.AC.UK
- META.json.in, META.yml.in, lcfg.yml: updated meta-data

* Wed Jun 24 2015 10:21  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, mapping_config.yml: added mapping for
  new perl_version method, needs newer version of LCFG::Build::PkgSpec

* Wed Jun 24 2015 10:10  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/OSXPkg.pm.in: Fix filtering for pkgbuild, closes:
  https://bugs.lcfg.org/show_bug.cgi?id=881, thanks to Kenny MacDonald for
  the patch

* Fri Oct 31 2014 10:52  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.5

* Fri Oct 31 2014 10:52  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/OSXPkg.pm.in: Fixed exit with a warning about the
  tmp dir, bug#791

* Wed Jul 02 2014 07:38  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.4

* Wed Jul 02 2014 07:38  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Added CentOS support

* Tue Jul 01 2014 16:05  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.3

* Tue Jul 01 2014 16:05  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec: Added missing build dep

* Tue Jul 01 2014 16:01  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Added support for detecting RHEL release

* Tue Apr 01 2014 14:43  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.2

* Tue Apr 01 2014 14:43  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: fixed missing closing brackets

* Tue Apr 01 2014 14:42  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.1

* Tue Apr 01 2014 14:42  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: only attempt to install a man page created
  using pod2man if it actually generated a file

* Fri Oct 11 2013 12:54  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.4.0

* Fri Oct 11 2013 12:53  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec, META.yml.in, Makefile.PL, lcfg.yml,
  lib/LCFG/Build/Tool.pm.in: Converted the detection of the revision
  control system to use the new auto_detect methods provided by the
  LCFG::Build::VCS modules in version 0.2.0. This should fix auto-detection
  for svn 1.7 and newer, see https://bugs.lcfg.org/show_bug.cgi?id=685

* Tue May 14 2013 08:12  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/CheckMacros.pm.in: Added new macros to the basic list

* Tue May 14 2013 08:09  squinney@INF.ED.AC.UK
- lcfg_config.yml: Added BOOTSTAMP and RELEASEFILE. This is primarily for
  building the LCFG client but other things might benefit as well

* Fri May 18 2012 17:03  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.3.1

* Fri May 18 2012 17:03  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.yml.in, Makefile.PL, README:
  Added the missing dependency on the Readonly module

* Fri May 18 2012 16:54  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.3.0

* Fri May 18 2012 16:54  squinney@INF.ED.AC.UK
- ., LCFG-Build-Tools.spec, MANIFEST, META.yml.in, lcfg.yml,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Utils/MacOSX.pm.in, lib/LCFG/Build/Utils/OSXPkg.pm.in,
  t/01_load.t: Implemented creating Apple Packages via the built in
  "pkgbuild" tool. This initial commit can only process projects that use
  CMake to build and install. Thanks go to Kenny MacDonald for adding this
  new functionality. This change closes
  https://bugs.lcfg.org/show_bug.cgi?id=565

* Thu Dec 22 2011 15:26  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.2.2

* Thu Dec 22 2011 15:26  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Applied patch to fix MacOSX support, see bug#304
  for details

* Wed Nov 09 2011 12:47  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.2.1

* Wed Nov 09 2011 12:46  squinney@INF.ED.AC.UK
- lcfg_config.yml, lib/LCFG/Build/Tool/CheckMacros.pm.in: Added LCFGRUN
  which is a macro which refers to a directory where component run files
  can be stored. Currently this is the same as LCFGTMP for
  backwards-compatibility reasons

* Thu Mar 03 2011 20:36  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.2.0

* Thu Mar 03 2011 20:30  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/RPM.pm.in: The parsing and formatting of the
  changelogs has been completely rewritten to make it more robust

* Wed Mar 02 2011 12:20  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.6

* Wed Mar 02 2011 12:20  squinney@INF.ED.AC.UK
- lcfg.yml, templates/lcfg.cmake.tt: Fixed SL6 support, rather annoyingly
  they have decided to change their LSB distributor ID string

* Fri Feb 18 2011 13:30  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.5

* Fri Feb 18 2011 13:30  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/Submit.pm.in: Fixed submit tool typos

* Thu Feb 17 2011 18:15  squinney@INF.ED.AC.UK
- Changes, lcfg.yml, lib/LCFG/Build/Tool/Submit.pm.in: LCFG-Build-Tools
  release: 0.1.4

* Thu Feb 17 2011 18:13  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool.pm.in: Fixed typo

* Thu Feb 17 2011 18:11  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: need to escape double-quotes in cmake strings

* Thu Feb 17 2011 17:01  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/RPM.pm.in: Added
  docs about the new --sign option

* Wed Feb 16 2011 14:40  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/RPM.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Added
  ability to pass the --sign option through to rpmbuild from the devrpm and
  rpm commands. This resolves https://bugs.lcfg.org/show_bug.cgi?id=387

* Mon Oct 11 2010 12:51  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.3

* Mon Oct 11 2010 12:45  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/DevRPM.pm.in: Set the build directory so
  that we can keep the build directory when making devel packages. This
  makes it easier to examine what has been generated

* Mon Oct 11 2010 12:44  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils/RPM.pm.in: Allow the calling code to specify the rpm
  BUILD directory

* Tue Jul 20 2010 13:13  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.2

* Tue Jul 20 2010 13:13  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Utils.pm.in: Report the
  full path to the generated tar file when using pack and devpack. This
  fixes https://bugs.lcfg.org/show_bug.cgi?id=293

* Tue Jul 20 2010 13:08  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.1

* Tue Jul 20 2010 13:08  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/Submit.pm.in: Added a
  new tool for submitting packages which have been built using build tools

* Tue Jul 20 2010 13:08  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Improved the setting of the cpack vendor field a
  bit more. Note this does not including the string reversal code from
  https://bugs.lcfg.org/show_bug.cgi?id=304, I'm not feeling brave enough
  today

* Mon Jul 12 2010 15:48  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.1.0

* Mon Jul 12 2010 15:48  squinney@INF.ED.AC.UK
- lcfg.yml: Noted Fedora 13 support

* Mon Jul 12 2010 15:47  squinney@INF.ED.AC.UK
- mapping_config.yml, templates/lcfg.cmake.tt: Reworked how
  CPACK_PACKAGE_VENDOR gets set so that it can be controlled from
  CMakeLists.txt

* Mon Jul 12 2010 15:44  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/RPM.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Completely
  reimplemented how RPMs get built to avoid a dependency on RPM4 which does
  not work with newer versions of rpmlib

* Mon Jul 12 2010 15:42  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: fixed the conditional which prevents the
  inclusion of *.cin templates for template files

* Mon Jul 12 2010 15:41  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Utils.pm.in: Fixed a bug where we did not return to the
  previous working directory after building the source tar file

* Mon Jul 12 2010 14:49  squinney@INF.ED.AC.UK
- LCFG-Build-Tools.spec: Added build-requirement on perl(Test::More)

* Mon Jul 12 2010 12:31  squinney@INF.ED.AC.UK
- lcfg.yml, templates/lcfg.cmake.tt: implemented most of patch to improve
  MacOSX support from https://bugs.lcfg.org/show_bug.cgi?id=304

* Mon Jul 12 2010 12:30  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Added support for isntalling the meta-files
  (README and ChangeLog) on MacOSX. This is done with the new
  lcfg_add_meta() macro. This is not necessary on Fedora/Redhat as it is
  handled in the specfile

* Mon Jul 12 2010 12:28  squinney@INF.ED.AC.UK
- mapping_config.yml: map vendor to CPACK_PACKAGE_VENDOR

* Mon Jul 12 2010 11:24  squinney@INF.ED.AC.UK
- mapping_config.yml: Added translation of major, minor and micro version
  fields into the relevant cpack variables. This fixes
  https://bugs.lcfg.org/show_bug.cgi?id=303

* Fri Feb 19 2010 12:02  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.61

* Fri Feb 19 2010 12:01  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Now allowing any files to be in the templates
  directory, previous restrictions were causing pain

* Fri Feb 19 2010 11:37  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.60

* Fri Feb 19 2010 11:37  squinney@INF.ED.AC.UK
- lcfg.yml, templates/build.cmake.tt: Rewrote the lcfg_add_templates()
  macro so that it supports including a tree of templates rather than just
  looking one-level deep

* Fri Feb 19 2010 10:30  squinney@INF.ED.AC.UK
- templates/lcfg.cmake.tt: Added detection of Fedora platforms. Thanks to
  Chris Cooke for the patch, this fixes:
  https://bugs.lcfg.org/show_bug.cgi?id=219

* Wed Feb 10 2010 14:39  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.59

* Wed Feb 10 2010 14:39  squinney@INF.ED.AC.UK
- templates/build.cmake.tt: Fixed small bug in Perl-module tree handling
  where it would also include the nagios tree when it exists

* Mon Jan 18 2010 18:09  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.58

* Mon Jan 18 2010 18:09  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tools.pm.in: Use the new 'allow_any_unambiguous_abbrev'
  option in App::Cmd rather than our hacky approach of overriding an
  internal method

* Mon Jan 18 2010 18:08  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MicroVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/SRPM.pm.in: The run() method is now named execute()

* Mon Jan 18 2010 18:07  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.yml.in, Makefile.PL, README:
  Upgrade to version 0.06 of MooseX::App::Cmd

* Fri Jul 03 2009 14:19  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.57

* Fri Jul 03 2009 14:17  squinney@INF.ED.AC.UK
- lib/LCFG/Build/Tool.pm.in: quiet attribute was missing the relevant
  metaclass specification

* Thu Apr 09 2009 07:53  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.56

* Thu Apr 09 2009 07:53  squinney@INF.ED.AC.UK
- lcfg.yml, lib/LCFG/Build/Utils.pm.in: Fixed a problem with not copying
  the mode when translating files prior to packing. Only affects packages
  using the translate_before_pack option which is not standard

* Fri Mar 13 2009 15:50  squinney@INF.ED.AC.UK
- Changes, lcfg.yml: LCFG-Build-Tools release: 0.0.55

* Fri Mar 13 2009 15:49  squinney@INF.ED.AC.UK
- Build.PL.in, LCFG-Build-Tools.spec, META.yml.in, Makefile.PL, README,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: switched from
  Date::Format to DateTime

* Wed Mar 11 2009 13:26  squinney@INF.ED.AC.UK
- bin/lcfg-reltool.in, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MicroVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/SRPM.pm.in, lib/LCFG/Build/Tools.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/MacOSX.pm.in,
  lib/LCFG/Build/Utils/RPM.pm.in: Set svn:keywords on the
  LCFG::Build::Tools Perl modules and scripts

* Mon Mar 09 2009 16:43  squinney
- lcfg.yml: Removed hardwired version-control type from lcfg.yml to allow
  future transfer to subversion

* Wed Feb 18 2009 14:53  squinney
- Changes, lcfg.yml: Release: 0.0.54

* Wed Feb 18 2009 14:53  squinney
- templates/build.cmake.tt: fixed small error in lcfg_pod2man

* Wed Feb 18 2009 12:36  squinney
- Changes, lcfg.yml: Release: 0.0.53

* Wed Feb 18 2009 12:36  squinney
- lcfg.yml, templates/build.cmake.tt, templates/lcfg.cmake.tt: Split the
  pod2man stuff into its own lcfg_pod2man() macro so it can be called
  separately without installing the pod file into the @LCFGPOD@ directory

* Mon Feb 02 2009 14:38  squinney
- lib/LCFG/Build/Utils/RPM.pm.in: added check that the specfile was
  successfully parsed

* Fri Jan 30 2009 14:11  squinney
- Changes, lcfg.yml: Release: 0.0.52

* Fri Jan 30 2009 14:10  squinney
- lcfg.yml, templates/lcfg.cmake.tt: Use CPack for MacOSX package building

* Fri Jan 30 2009 14:10  squinney
- lib/LCFG/Build/Utils/MacOSX.pm.in: We do not need to generate plist files
  for MacOSX, CPack will handle it all

* Thu Dec 11 2008 14:43  squinney
- Changes, lcfg.yml: Release: 0.0.51

* Thu Dec 11 2008 14:42  squinney
- lib/LCFG/Build/Tool.pm.in: Added basic auto-detection of the version
  control system

* Wed Dec 10 2008 16:22  squinney
- templates/build.cmake.tt: Automatically create CONFIGDIR for components

* Fri Dec 05 2008 12:48  squinney
- Changes, lcfg.yml: Release: 0.0.50

* Fri Dec 05 2008 12:47  squinney
- lcfg.yml, templates/build.cmake.tt: Second attempt to handle
  automatically installing templates

* Fri Dec 05 2008 12:05  squinney
- Changes, lcfg.yml: Release: 0.0.49

* Fri Dec 05 2008 12:05  squinney
- templates/build.cmake.tt: Added support for automatically installing
  templates found in a templates directory

* Thu Nov 27 2008 19:45  squinney
- Changes, lcfg.yml: Release: 0.0.48

* Thu Nov 27 2008 19:45  squinney
- templates/build.cmake.tt: Fixed nagios module path

* Tue Nov 18 2008 14:30  squinney
- Changes, lcfg.yml: Release: 0.0.47

* Tue Nov 18 2008 14:30  squinney
- templates/build.cmake.tt: Added cmake macros lcfg_add_nagios_module() to
  do-the-right-thing with LCFG nagios configuration modules and
  lcfg_add_nagios_support() to call that for every module it finds in the
  nagios directory for a project. lcfg_add_nagios_support() is called for
  every component project, if there is not a nagios directory then it
  achieves nothing.

* Tue Nov 18 2008 14:12  squinney
- Changes, lcfg.yml: Release: 0.0.46

* Tue Nov 18 2008 14:12  squinney
- templates/lcfg.cmake.tt: Improved the fix for the OS_VERSION detection.
  It now behaves the same as the old buildtools. There is a new variable
  naemd OS_ID which gives the complete (arch-specific) name of the platform

* Tue Nov 11 2008 10:14  squinney
- Changes, lcfg.yml: Release: 0.0.45

* Tue Nov 11 2008 10:14  squinney
- templates/lcfg.cmake.tt: Fixed OS_VERSION macro for 64bit linux platforms

* Wed Oct 29 2008 15:22  squinney
- Changes, lcfg.yml: Release: 0.0.44

* Wed Oct 29 2008 15:21  squinney
- lib/LCFG/Build/Tool/RPM.pm.in: Fixed abstract for LCFG::Build::Tool::RPM

* Wed Oct 29 2008 15:20  squinney
- lib/LCFG/Build/Tool/SRPM.pm.in: Fixed abstract for
  LCFG::Build::Tool::SRPM

* Tue Oct 28 2008 10:42  squinney
- Changes, lcfg.yml: Release: 0.0.43

* Tue Oct 28 2008 10:42  squinney
- templates/cmake.tt: Slightly altered cmake.tt template so that it is more
  generic

* Mon Oct 27 2008 09:04  squinney
- Changes, lcfg.yml: Release: 0.0.42

* Mon Oct 27 2008 09:04  squinney
- MANIFEST: Fixed MANIFEST

* Mon Oct 27 2008 09:03  squinney
- Changes, lcfg.yml: Release: 0.0.41

* Mon Oct 27 2008 09:02  squinney
- META.yml.in, bin/lcfg-reltool.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MicroVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tools.pm.in,
  t/01_load.t: Renamed LCFG::Build::Tool::Release as
  LCFG::Build::Tool::MicroVersion

* Wed Oct 08 2008 13:41  squinney
- Changes, lcfg.yml: Release: 0.0.40

* Wed Oct 08 2008 13:40  squinney
- lib/LCFG/Build/Tool/CheckMacros.pm.in: Added a new --fix_deprecated
  option to the CheckMacros tool to replace any usage of deprecated macros
  in the scanned files with the modern equivalent

* Fri Oct 03 2008 12:55  squinney
- Changes, lcfg.yml: Release: 0.0.39

* Fri Oct 03 2008 12:54  squinney
- lib/LCFG/Build/Tool/CheckMacros.pm.in, templates/build.cmake.tt: Added a
  new CMake variable - LCFG_TMPLDIR which is the component-specific
  template location. Also added a new CMake macro - lcfg_add_template() to
  install template files into that location

* Fri Oct 03 2008 12:53  squinney
- templates/lcfg.cmake.tt: Fixed the setting of the OS_VERSION CMake
  variable on Scientific Linux machines

* Fri Sep 12 2008 14:07  squinney
- Changes, lcfg.yml: Release: 0.0.38

* Fri Sep 12 2008 14:05  squinney
- Build.PL.in, LCFG-Build-Tools.spec, META.yml, META.yml.in, Makefile.PL,
  lcfg.yml, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils.pm.in,
  lib/LCFG/Build/Utils/MacOSX.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Lots
  of documentation improvements. Various work on making the file and
  directory path handling more platform-independent

* Tue Sep 09 2008 10:38  squinney
- Changes, lcfg.yml: Release: 0.0.37

* Tue Sep 09 2008 10:38  squinney
- lcfg.yml, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Tools.pm.in: Use make_immutable for each Moose class.
  According to the docs this should provide a good speed-up in code loading

* Tue Sep 09 2008 09:59  squinney
- Changes, lcfg.yml: Release: 0.0.36

* Tue Sep 09 2008 09:59  squinney
- lcfg.yml, lib/LCFG/Build/Tool/DevOSXPkg.pm.in,
  lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/OSXPkg.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Tool/RPM.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/MacOSX.pm.in,
  lib/LCFG/Build/Utils/RPM.pm.in: Removed the genmeta options from the
  package building tools. Used Module::Pluggable to add a new
  LCFG::Build::Utils plugins() method which lists all available Utils
  sub-classes. Switched generate_metadata() and build() to be methods to
  make it easier to test for existence and call without a string eval

* Mon Sep 08 2008 13:24  squinney
- Changes, lcfg.yml: Release: 0.0.35

* Mon Sep 08 2008 13:22  squinney
- bin/lcfg-reltool.in, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils.pm.in,
  lib/LCFG/Build/Utils/MacOSX.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Lots
  of documentation improvements

* Mon Sep 08 2008 12:33  squinney
- Changes, lcfg.yml: Release: 0.0.34

* Mon Sep 08 2008 12:32  squinney
- LCFG-Build-Tools.spec, MANIFEST, lcfg.yml: Now using the new support for
  removing input files after substitution. Also corrected a couple of bits
  in the specfile.

* Mon Sep 08 2008 12:26  squinney
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/RPM.pm.in: Added support
  for removing input files after macro substitution has been completed.
  Also switched the source tar file generation sequence so that the packing
  happens last which allows the inclusion of generated metadata files

* Mon Sep 08 2008 12:24  squinney
- lib/LCFG/Build/Tools.pm.in: Added some high-level documentation to
  LCFG::Build::Tools

* Mon Sep 08 2008 12:23  squinney
- LCFG-Build-Tools.spec: Improved specfile

* Mon Sep 08 2008 12:23  squinney
- Build.PL.in, Makefile.PL, README: Updated perl build files

* Mon Sep 08 2008 12:22  squinney
- MANIFEST: Updated package MANIFEST

* Tue Sep 02 2008 11:35  squinney
- Changes, lcfg.yml: Release: 0.0.33

* Tue Sep 02 2008 11:34  squinney
- lcfg.yml, lib/LCFG/Build/Utils/MacOSX.pm.in, templates/build.cmake.tt:
  Fixed a problem with pod2man not working if the group argument, which
  gets passed into the --center option, was not specified

* Thu Aug 07 2008 12:05  squinney
- Changes, lcfg.yml: Release: 0.0.32

* Thu Aug 07 2008 12:05  squinney
- Build.PL.in, LCFG-Build-Tools.spec, MANIFEST, lcfg.yml,
  lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/CheckMacros.pm.in,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in, lib/LCFG/Build/Tool/OSXPkg.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tool/SRPM.pm.in,
  lib/LCFG/Build/Tools.pm.in, lib/LCFG/Build/Utils.pm.in,
  lib/LCFG/Build/Utils/MacOSX.pm.in, lib/LCFG/Build/Utils/RPM.pm.in,
  t/02_macros.t, t/macros.tmpl, t/macros.txt: Lots of small changes to
  satisfy perltidy and perlcritic

* Wed Aug 06 2008 15:49  squinney
- Changes, lcfg.yml: Release: 0.0.31

* Wed Aug 06 2008 15:49  squinney
- LCFG-Build-Tools.spec, t, t/01_load.t: Added a basic test to check that
  all Perl modules are loadable. Also added all the necessary build
  dependencies so this check can be carried out in a chroot

* Wed Aug 06 2008 14:25  squinney
- Changes, lcfg.yml: Release: 0.0.30

* Wed Aug 06 2008 14:24  squinney
- Build.PL.in, LCFG-Build-Tools.spec, MANIFEST, lcfg.yml,
  lib/LCFG/Build/Tool/DevOSXPkg.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/OSXPkg.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Utils.pm.in, lib/LCFG/Build/Utils/MacOSX.pm.in,
  templates/Description.plist.tmpl, templates/Info.plist.tmpl: Added basic
  MacOSX support, stubs for the ospkg and devospkg command modules are now
  supplied

* Tue Aug 05 2008 14:29  squinney
- Changes, lcfg.yml: Release: 0.0.29

* Tue Aug 05 2008 14:29  squinney
- lib/LCFG/Build/Tool/CheckMacros.pm.in: Added a new checkmacros command

* Wed Jul 30 2008 20:17  squinney
- Changes, lcfg.yml: Release: 0.0.28

* Wed Jul 30 2008 20:16  squinney
- lib/LCFG/Build/Tool/SRPM.pm.in: overrode sourceonly and deps attributes
  from LCFG::Build::Tool::SRPM so they don't show up as options for the
  srpm command

* Wed Jul 30 2008 20:14  squinney
- lib/LCFG/Build/Tool/RPM.pm.in: Removed srpm method from
  LCFG::Build::Tool::RPM as it is no longer needed

* Wed Jul 30 2008 20:00  squinney
- bin/lcfg-reltool.in: switch lcfg-reltool to using LCFG::Build::Tools and
  updated the docs a bit

* Wed Jul 30 2008 19:59  squinney
- lib/LCFG/Build/Tool/SRPM.pm.in: Added the srpm command for convenience

* Wed Jul 30 2008 19:58  squinney
- lib/LCFG/Build/Tools.pm.in: Documented override of the App::Cmd
  _prepare_command method in LCFG::Build::Tools

* Wed Jul 30 2008 19:34  squinney
- lib/LCFG/Build/Tools.pm.in: attempt to handle abbreviated command names

* Wed Jul 30 2008 18:53  squinney
- lib/LCFG/Build/Tool/Release.pm.in: Fixed LCFG::Build::Tool::Release run
  method

* Wed Jul 30 2008 18:48  squinney
- lib/LCFG/Build/Tool/Release.pm.in: Document why the resultsdir is
  overridden in LCFG::Build::Tool::Release

* Wed Jul 30 2008 18:19  squinney
- lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in: Fixed overrides

* Wed Jul 30 2008 18:17  squinney
- lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in: Moved resultsdir option to the top-level
  LCFG::Build::Tool class

* Wed Jul 30 2008 18:08  squinney
- lib/LCFG/Build/Tool/MajorVersion.pm.in,
  lib/LCFG/Build/Tool/MinorVersion.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in: Added majorversion and minorversion
  tools

* Wed Jul 30 2008 16:31  squinney
- templates/build.cmake.tt: Removed lcfg_add_doc CMake macro as it is
  unnecessary

* Wed Jul 30 2008 16:30  squinney
- lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Tool/RPM.pm.in, lib/LCFG/Build/Tool/Release.pm.in: Added
  documentation for the commands and the options

* Wed Jul 30 2008 16:28  squinney
- LCFG-Build-Tools.spec: Added requirement for perl(MooseX::App::Cmd) to
  the specfile

* Wed Jul 30 2008 15:24  squinney
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in: Converted to MooseX::App::Cmd

* Wed Jul 30 2008 14:47  squinney
- lib/LCFG/Build/Tool.pm.in, lib/LCFG/Build/Tools.pm.in: Switched to using
  App::Cmd

* Fri Jul 25 2008 12:49  squinney
- Changes, lcfg.yml: Release: 0.0.27

* Fri Jul 25 2008 12:48  squinney
- lcfg.yml, templates/build.cmake.tt, templates/lcfg.cmake.tt: Added
  handling of logrotate files. Improved handling of bin and sbin files

* Fri Jul 25 2008 12:44  squinney
- lcfg_config.yml: Added INITDIR macro

* Tue Jul 22 2008 15:44  squinney
- Changes, lcfg.yml: Release: 0.0.26

* Tue Jul 22 2008 15:43  squinney
- templates/lcfg.cmake.tt: Set MSG variable

* Tue Jul 22 2008 10:40  squinney
- Changes, lcfg.yml: Release: 0.0.25

* Tue Jul 22 2008 10:39  squinney
- templates/lcfg.cmake.tt: Added ICONDIR, SCRIPTDIR, HAS_PROC and BOOTCOMP
  cmake variables. Also added bash detection

* Tue Jul 22 2008 10:34  squinney
- templates/build.cmake.tt: Fixed cmake lcfg_add_schema macro so it works
  for all values

* Fri Jul 18 2008 13:19  squinney
- Changes, lcfg.yml: Release: 0.0.24

* Fri Jul 18 2008 13:18  squinney
- templates/build.cmake.tt: Split out from lcfg_add_pod() an lcfg_add_man()
  macro

* Fri Jul 18 2008 10:59  squinney
- Changes, lcfg.yml: Release: 0.0.23

* Fri Jul 18 2008 10:59  squinney
- templates/lcfg.cmake.tt: Added LIBDIR and LIBSECURITYDIR variables. Also
  now handle the correct setting of PERL_LIBDIR and PERL_ARCHDIR based on
  whether the builder wants site or vendor locations.

* Fri Jul 18 2008 10:57  squinney
- templates/build.cmake.tt: Added support for installing perl modules with
  lcfg_add_perl_module() and lcfg_add_perl_tree().

* Thu Jul 17 2008 15:16  squinney
- Changes, lcfg.yml: Release: 0.0.22

* Thu Jul 17 2008 15:16  squinney
- lcfg.yml, templates/build.cmake.tt: Improved handling of POD files

* Tue Jul 15 2008 10:51  squinney
- Changes, lcfg.yml: Release: 0.0.21

* Tue Jul 15 2008 10:50  squinney
- lib/LCFG/Build/Utils/RPM.pm.in: Rewrote the build method in Utils::RPM to
  avoid using RPM4::Spec::rpmbuild which appears to be weirdly broken

* Fri Jul 11 2008 14:22  squinney
- Changes, lcfg.yml: Release: 0.0.20

* Fri Jul 11 2008 14:20  squinney
- templates/build.cmake.tt, templates/lcfg.cmake.tt: Added detection of the
  perl executable and fixed usage of lsb detection for linux

* Fri Jul 11 2008 14:19  squinney
- lib/LCFG/Build/Utils.pm.in: Fixed find_trans_files to return relative
  paths

* Thu Jul 10 2008 09:15  squinney
- Changes, lcfg.yml: Release: 0.0.19

* Thu Jul 10 2008 09:14  squinney
- bin/lcfg-reltool.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Utils/RPM.pm.in: Added a shortcut command for building an
  srpm. Added some error handling for when rpmbuild fails

* Thu Jul 10 2008 09:06  squinney
- Changes, lcfg.yml: Release: 0.0.18

* Thu Jul 10 2008 09:05  squinney
- lcfg.yml, lib/LCFG/Build/Utils.pm.in: Rewrote
  LCFG::Build::Utils::translate_string() so that it only substitutes known
  macros. It is also now much easier to extend with new macro styles.
  Changed the behaviour of LCFG::Build::Utils::translate_macro() so it
  returns undef for an unknown macro

* Wed Jul 09 2008 15:56  squinney
- Changes, lcfg.yml: Release: 0.0.17

* Wed Jul 09 2008 15:56  squinney
- lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/RPM.pm.in: Fixed
  mistake with printing out the binary RPM filenames in Tool::RPM and
  Tool::DevRPM

* Wed Jul 09 2008 14:21  squinney
- Changes, lcfg.yml: Release: 0.0.16

* Wed Jul 09 2008 14:20  squinney
- lcfg.yml, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in: Fixed bug where Tool::Pack used the
  devel-tree metadata file instead of that from the tagged-tree

* Tue Jul 08 2008 09:57  squinney
- Changes, lcfg.yml: Release: 0.0.15

* Tue Jul 08 2008 09:54  squinney
- lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/RPM.pm.in: This
  time the logging of results from Tool::RPM and Tool::DevRPM might
  actually be correct...

* Tue Jul 08 2008 09:45  squinney
- Changes, lcfg.yml: Release: 0.0.14

* Tue Jul 08 2008 09:44  squinney
- lib/LCFG/Build/Tool/DevPack.pm.in, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/Pack.pm.in, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm.in, lib/LCFG/Build/Tools.pm.in: Various
  documentation improvements

* Tue Jul 08 2008 09:28  squinney
- Changes, lcfg.yml: Release: 0.0.13

* Tue Jul 08 2008 09:28  squinney
- lib/LCFG/Build/Tool/DevRPM.pm.in, lib/LCFG/Build/Tool/RPM.pm.in: Fixed
  log messages in Tool::RPM and Tool::DevRPM

* Tue Jul 08 2008 09:21  squinney
- Changes, lcfg.yml: Release: 0.0.12

* Tue Jul 08 2008 09:21  squinney
- LCFG-Build-Tools.spec: Fixed specfile so that *.in files do not get
  included

* Tue Jul 08 2008 09:19  squinney
- LCFG-Build-Tools.spec: Added into the specfile a list of Perl module
  dependencies which get missed by the automatic Perl dep finder since they
  are loaded through 'require' rather than 'use'

* Mon Jul 07 2008 14:33  squinney
- Changes, lcfg.yml: Release: 0.0.11

* Mon Jul 07 2008 14:32  squinney
- lib/LCFG/Build/Utils, lib/LCFG/Build/Utils/RPM.pm.in: Forgot to add the
  Utils::RPM module into CVS

* Mon Jul 07 2008 14:30  squinney
- Changes, lcfg.yml: Release: 0.0.10

* Mon Jul 07 2008 14:29  squinney
- Build.PL, Build.PL.in, bin/lcfg-reltool, bin/lcfg-reltool.in,
  lib/LCFG/Build/Tool.pm, lib/LCFG/Build/Tool.pm.in,
  lib/LCFG/Build/Tool/DevPack.pm, lib/LCFG/Build/Tool/DevPack.pm.in,
  lib/LCFG/Build/Tool/DevRPM.pm, lib/LCFG/Build/Tool/DevRPM.pm.in,
  lib/LCFG/Build/Tool/Pack.pm, lib/LCFG/Build/Tool/Pack.pm.in,
  lib/LCFG/Build/Tool/RPM.pm, lib/LCFG/Build/Tool/RPM.pm.in,
  lib/LCFG/Build/Tool/Release.pm, lib/LCFG/Build/Tool/Release.pm.in,
  lib/LCFG/Build/Tools.pm, lib/LCFG/Build/Tools.pm.in,
  lib/LCFG/Build/Utils, lib/LCFG/Build/Utils.pm,
  lib/LCFG/Build/Utils.pm.in: Lots more documentation of modules. Moved
  various files to .in versions for macro substitution

* Mon Jul 07 2008 12:00  squinney
- Changes, lcfg.yml: Release: 0.0.9

* Mon Jul 07 2008 11:59  squinney
- Build.PL, lib/LCFG/Build/Utils.pm, lib/LCFG/Build/Utils/RPM.pm:
  Documented LCFG::Build::Utils and LCFG::Build::Utils::RPM, also tidied
  code to satisfy perllint and perlcritic

* Mon Jul 07 2008 08:49  squinney
- Changes, lcfg.yml: Release: 0.0.8

* Mon Jul 07 2008 08:49  squinney
- lcfg.yml, lib/LCFG/Build/Tool.pm, lib/LCFG/Build/Tool/Release.pm,
  lib/LCFG/Build/Utils.pm, lib/LCFG/Build/Utils/RPM.pm: Extracted metafile
  templating from Utils::RPM to Utils so it can be used anywhere. Added a
  couple of missing module dependencies and tidied up a couple of sections

* Mon Jun 30 2008 15:40  squinney
- lib/LCFG/Build/Tools: removed LCFG::Build::Tools::Release as it has been
  renamed to LCFG::Build::Tool::Release

* Wed Jun 25 2008 14:51  squinney
- Changes, lcfg.yml: Release: 0.0.7

* Wed Jun 25 2008 14:50  squinney
- LCFG-Build-Tools.spec: Fixed prep stage in specfile

* Wed Jun 25 2008 14:48  squinney
- Changes, lcfg.yml: Release: 0.0.6

* Wed Jun 25 2008 14:48  squinney
- LCFG-Build-Tools.spec: Moved from static specfile to using macros

* Wed Jun 25 2008 14:41  squinney
- Changes, lcfg.yml: Release: 0.0.5

* Wed Jun 25 2008 14:41  squinney
- lib/LCFG/Build/Tool/DevRPM.pm, lib/LCFG/Build/Tool/Pack.pm,
  lib/LCFG/Build/Tool/RPM.pm: Added various extra release tools modules

* Wed Jun 25 2008 14:40  squinney
- Changes, LCFG-Build-Tools.spec, MANIFEST, META.yml, Makefile.PL,
  bin/lcfg-buildrpm, bin/lcfg-buildtool, bin/lcfg-gencmake,
  bin/lcfg-reltool, lcfg.yml, lib/LCFG/Build/Tool.pm,
  lib/LCFG/Build/Tool/DevPack.pm, lib/LCFG/Build/Tool/Release.pm,
  lib/LCFG/Build/Tools.pm, lib/LCFG/Build/Utils.pm,
  lib/LCFG/Build/Utils/RPM.pm: Release: 0.0.4

* Wed Jun 04 2008 16:13  squinney
- Build.PL, MANIFEST, MANIFEST.SKIP, META.yml, Makefile.PL, README,
  bin/lcfg-reltool, lcfg.yml, lib/LCFG/Build/Tool, lib/LCFG/Build/Tool.pm,
  lib/LCFG/Build/Tool/DevPack.pm, lib/LCFG/Build/Tool/Release.pm,
  lib/LCFG/Build/Tools/Release.pm, lib/LCFG/Build/Utils,
  lib/LCFG/Build/Utils.pm, lib/LCFG/Build/Utils/RPM.pm: Added lots more
  code

* Wed Jun 04 2008 16:11  squinney
- lib/LCFG/Build/Tools.pm: Renamed LCFG::Build::Tools to LCFG::Build::Tool

* Wed Jun 04 2008 15:17  squinney
- lib/LCFG/Build/Tools/RPM.pm: removed file

* Wed May 28 2008 14:31  squinney
- Changes, bin/lcfg-reltool, lcfg.yml, lib/LCFG/Build/Tools.pm,
  lib/LCFG/Build/Tools/Release.pm: Release: 0.0.3

* Tue May 13 2008 11:00  squinney
- LCFG-Build-Tools.spec, bin/lcfg-buildtool, bin/lcfg-reltool,
  lib/LCFG/Build/Tools.pm, lib/LCFG/Build/Tools/RPM.pm,
  templates/build.cmake.tt, templates/lcfg.cmake.tt: Moved lcfg-reltool to
  this package to simplify dependencies

* Thu May 08 2008 08:51  squinney
- Changes, LCFG-Build-Tools.spec, bin/lcfg-buildrpm, lib/LCFG/Build/Tools,
  lib/LCFG/Build/Tools/RPM.pm: Added more stuff

* Thu May 08 2008 08:29  squinney
- bin/lcfg-gencmake, lcfg.yml, lib/LCFG/Build/Tools.pm, mapping_config.yml,
  templates/build.cmake.tt, templates/cmake.tt, templates/lcfg.cmake.tt:
  Added lots of stuff

* Tue May 06 2008 16:02  squinney
- lcfg.yml: Release: 0.0.2

* Tue May 06 2008 16:02  squinney
- bin, bin/lcfg-buildtool, bin/lcfg-gencmake, lcfg.yml, lcfg_config.yml,
  lib, lib/LCFG, lib/LCFG/Build, lib/LCFG/Build/Tools.pm,
  mapping_config.yml, templates, templates/build.cmake.tt,
  templates/cmake.tt, templates/lcfg.cmake.tt: Added lots of files to CVS

* Tue May 06 2008 16:02  
- .: Standard project directories initialized by cvs2svn.


