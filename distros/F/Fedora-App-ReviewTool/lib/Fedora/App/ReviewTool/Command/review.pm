#!/usr/bin/perl

package Fedora::App::ReviewTool::Command::review;

=head1 NAME

Fedora::App::ReviewTool::Command::review - [reviewer] review a package

=cut

use Moose;

# FIXME still need to migrate this to our app class
#use Data::Section -setup;
use IO::Prompt;
use Path::Class;
use Readonly;

# debugging
#use Smart::Comments;

extends qw{ MooseX::App::Cmd::Command };

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Reviewer';

sub _sections { qw{ bugzilla fas } }

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;

    print "Retrieving reviews status from bugzilla....\n\n";
    my $bugs = $self->find_my_active_reviews;
    print $bugs->num_ids . " bugs found.\n\n";
    print $self->bug_table($bugs) if $bugs->num_ids;

    # right now we assume we've been passed either bug ids or aliases; ideally
    # we should even search for a given review ticket from a package name

    return unless $self->yes || prompt 'Begin reviews? ', -YyNn1;

    PKG_LOOP:
    for my $bug ($bugs->bugs) {
    
        my $name = $bug->package_name;
        print "\nFound bug $bug; $name.\n";
        $self->do_review($bug) 
            if $self->yes || prompt 'Begin review? ', -YyNn1;
        
    }
}

1;
__DATA__
__[ rpm_makefile ]__

NAME := [% name %]
SPECFILE = $(firstword $(wildcard *.spec))

srpm:

build:

review: srpm

foo:
	ksjdladj


__[ new_tix ]__
Spec URL: [% spec %]
SRPM URL: [% srpm %]

Description:
[% description %]

[% IF koji %]
Koji build: [% koji %]
[% END %]
__[ review_tibbs ]__
source files match upstream:
 (I generally include the checksum from the script below)
package meets naming and versioning guidelines.
specfile is properly named, is cleanly written and uses macros consistently.
dist tag is present.
build root is correct.
 (%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
     is the recommended value, but not the only one)
license field matches the actual license.
license is open source-compatible.
 (include one of the below)
license text not included upstream.
license text included in package.
latest version is being packaged.
BuildRequires are proper.
compiler flags are appropriate.
%clean is present.
package builds in mock.
package installs properly.
debuginfo package looks complete.
rpmlint is silent.
final provides and requires are sane:
  (paste in the rpm -qp --provides and --requires output)
%check is present and all tests pass:
  (if possible, include some info indicating a successful test suite)
  (it's OK if there's no test suite, but if one is there it should be run if possible)
no shared libraries are added to the regular linker search paths.
  (or, if shared libraries are present, make sure ldconfig is run)
owns the directories it creates.
doesn't own any directories it shouldn't.
no duplicates in %files.
file permissions are appropriate.
no scriptlets present.
  (or, if scriptlets are present, compare them against the ScriptletSnippets page)
code, not content.
documentation is small, so no -docs subpackage is necessary.
%docs are not necessary for the proper functioning of the package.
no headers.
no pkgconfig files.
no libtool .la droppings.
desktop files valid and installed properly.

__[ review_pedantic ]__

Here is the review:

 +:ok, =:needs attention, -:needs fixing

MUST Items:
[] MUST: rpmlint must be run on every package.
<<output if not already posted>>
[] MUST: The package must be named according to the Package Naming Guidelines.
[] MUST: The spec file name must match the base package %{name}
[] MUST: The package must meet the Packaging Guidelines. [FIXME?: covers this list and more]
[] MUST: The package must be licensed with a Fedora approved license and meet the Licensing Guidelines.
[] MUST: The License field in the package spec file must match the actual license.
[] MUST: If (and only if) the source package includes the text of the license(s) in its own file, then that file, containing the text of the license(s) for the package must be included in %doc.
[] MUST: The spec file must be written in American English.
[] MUST: The spec file for the package MUST be legible.
[] MUST: The sources used to build the package must match the upstream source, as provided in the spec URL.
<<md5sum checksum>>
[] MUST: The package must successfully compile and build into binary rpms on at least one supported architecture.
[] MUST: If the package does not successfully compile, build or work on an architecture, then those architectures should be listed in the spec in ExcludeArch.
[] MUST: All build dependencies must be listed in BuildRequires
[] MUST: The spec file MUST handle locales properly. This is done by using the %find_lang macro.
[] MUST: Every binary RPM package which stores shared library files (not just symlinks) in any of the dynamic linker's default paths, must call ldconfig in %post and %postun.
[] MUST: If the package is designed to be relocatable, the packager must state this fact in the request for review
[] MUST: A package must own all directories that it creates. If it does not create a directory that it uses, then it should require a package which does create that directory.
[] MUST: A package must not contain any duplicate files in the %files listing.
[] MUST: Permissions on files must be set properly. Executables should be set with executable permissions, for example. Every %files section must include a %defattr(...) line.
[] MUST: Each package must have a %clean section, which contains rm -rf %{buildroot} (or $RPM_BUILD_ROOT).
[] MUST: Each package must consistently use macros, as described in the macros section of Packaging Guidelines.
[] MUST: The package must contain code, or permissible content. This is described in detail in the code vs. content section of Packaging Guidelines.
[] MUST: Large documentation files should go in a doc subpackage.
[] MUST: If a package includes something as %doc, it must not affect the runtime of the application.
[] MUST: Header files must be in a -devel package.
[] MUST: Static libraries must be in a -static package.
[] MUST: Packages containing pkgconfig(.pc) files must 'Requires: pkgconfig' (for directory ownership and usability).
[] MUST: If a package contains library files with a suffix (e.g. libfoo.so.1.1), then library files that end in .so (without suffix) must go in a -devel package.
[] MUST: In the vast majority of cases, devel packages must require the base package using a fully versioned dependency: Requires: %{name} = %{version}-%{release} 
[] MUST: Packages must NOT contain any .la libtool archives, these should be removed in the spec.
[] MUST: Packages containing GUI applications must include a %{name}.desktop file, and that file must be properly installed with desktop-file-install in the %install section.
[] MUST: Packages must not own files or directories already owned by other packages.
[] MUST: At the beginning of %install, each package MUST run rm -rf %{buildroot} (or $RPM_BUILD_ROOT).
[] MUST: All filenames in rpm packages must be valid UTF-8.

SHOULD Items:
[] SHOULD: If the source package does not include license text(s) as a separate file from upstream, the packager SHOULD query upstream to include it.
[] SHOULD: The description and summary sections in the package spec file should contain translations for supported Non-English languages, if available.
[] SHOULD: The reviewer should test that the package builds in mock.
[] SHOULD: The package should compile and build into binary rpms on all supported architectures.
[] SHOULD: The reviewer should test that the package functions as described.
[] SHOULD: If scriptlets are used, those scriptlets must be sane.
[] SHOULD: Usually, subpackages other than devel should require the base package using a fully versioned dependency.
[] SHOULD: The placement of pkgconfig(.pc) files depends on their usecase, and this is usually for development purposes, so should be placed in a -devel pkg. A reasonable exception is that the main pkg itself is a devel tool not installed in a user runtime, e.g. gcc or gdb.
[] SHOULD: If the package has file dependencies outside of /etc, /bin, /sbin, /usr/bin, or /usr/sbin consider requiring the package which provides the file instead of the file itself.
[] SHOULD: Packages should try to preserve timestamps of original installed files.
