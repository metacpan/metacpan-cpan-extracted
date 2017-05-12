package Dist::Zilla::Plugin::TravisYML;

our $AUTHORITY = 'cpan:BBYRD'; # AUTHORITY
our $VERSION = '1.15'; # VERSION
# ABSTRACT: creates a .travis.yml file for Travis CI

use v5.10;
use Moose;

use Dist::Zilla::File::InMemory;
use List::AllUtils 'first';

# DZIL role ordering gets really weird here...

# FilePruner   - Since the .travis.yml file doesn't belong in the build
# InstallTool  - Both cases need to be here after prereqs are built
# AfterRelease - So that we have the build version in the build directory for Git::CommitBuild

with 'Dist::Zilla::Role::FilePruner';
with 'Dist::Zilla::Role::InstallTool';
with 'Dist::Zilla::Role::AfterRelease';

with 'Dist::Zilla::Role::FileInjector';
with 'Dist::Zilla::Role::TravisYML';

around mvp_multivalue_args => sub {
   my ($orig, $self) = @_;

   my @start = $self->$orig;
   return (
      @start, qw(notify_email notify_irc irc_template extra_env),
      ### XXX: Yes, this ends up being 7*3*3=63 attributes, but such is the price of progress...
      (
         map { $_, $_.'_dzil', $_.'_build' }
         map { $_, 'pre_'.$_, 'post_'.$_ }
         @Dist::Zilla::Role::TravisYML::phases
      ),
   );
};

sub prune_files {
   my ($self) = @_;
   my $file = first { $_->name eq '.travis.yml' } @{$self->zilla->files};

   ### !!! NINJA !!! ###
   $self->zilla->prune_file($file) if $file;
}

# Yes, this plugin has nothing to do with installers, but this is the only way to:
#
# 1. Make sure things like PruneCruft don't interfere with YAML building.
# 2. Create the YAML file -after- prereqs have been finalized
# 3. Do it in a way that doesn't actually add any files into the build dir or tar.gz.
#
# See also: https://github.com/SineSwiper/Dist-Zilla-TravisCI/issues/11

sub setup_installer {
   my $self = shift;
   $self->build_travis_yml;  # Not much here... most of the magic is in the role
}

sub after_release {
   my $self = shift;
   return unless $self->build_branch;
   my $file = $self->build_travis_yml(1) || return;

   # Now we have to add the file back in
   $self->add_file(
      # Since we put the file in the build directory, we have to use InMemory to
      # prevent the file paths from getting mismatched with what is in zilla->files
      Dist::Zilla::File::InMemory->new({
         name    => '.travis.yml',
         content => scalar $file->slurp,
         mode    => $file->stat->mode & 0755, # kill world-writeability
      })
   );
}

__PACKAGE__->meta->make_immutable;
42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::TravisYML - creates a .travis.yml file for Travis CI

=head1 SYNOPSIS

    [TravisYML]
    ; defaults
    build_branch = /^build\/.*/
    notify_email = 1
    notify_irc   = 0
    mvdt         = 0
    sudo         = 0
 
    ; These options are probably a good idea
    ; if you are going to use a build_branch
    [Git::CommitBuild]
    release_branch  = build/%b
    release_message = Release build of v%v (on %b)
 
    [@Git]
    allow_dirty = dist.ini
    allow_dirty = README
    allow_dirty = .travis.yml
    push_to = origin master:master
    push_to = origin build/master:build/master

=head1 DESCRIPTION

This plugin creates a C<<< .travis.yml >>> file in your distro for CI smoke testing (or what we like
to call L<"chain smoking"|Dist::Zilla::App::Command::chainsmoke/CHAIN SMOKING?>).  It will also
(optionally) create a separate C<<< .travis.yml >>> file for your build directory after a release.

Why two files?  Because chain smoking via DZIL will work a lot differently than a traditional
C<<< Makefile.PL; make >>>.  This tests both your distribution repo environment as well as what a
CPAN user would see.

Of course, you still need to L<turn on Travis CI|http://docs.travis-ci.com/user/getting-started/>
and the remote still needs to be a GitHub repo for any of this to work.

=head1 OPTIONS

=head2 build_branch

This is a regular expression indicating which (build) branches are okay for running through
Travis CI, per the L<configuration|http://about.travis-ci.org/docs/user/build-configuration/>'s
branch whitelist option.  The value will be inserted directly as an C<<< only >>> clause.  The default
is C<<< /^build\/.*/ >>>.

This more or less requires L<Git::CommitBuild|Dist::Zilla::Plugin::Git::CommitBuild> to work.
(Ordering is important, too.  TravisYML comes before Git::CommitBuild.)  You should change
this to match up with the C<<< release_branch >>> option, if your build branch is not going to reside
in a C<<< build/* >>> structure.

Also, if you want to disable build branch testing, you can set this to C<<< 0 >>>.

=head2 dzil_branch

Like C<<< build_branch >>>, this is a regular expression indicating which branches are okay for
running through Travis CI for DZIL chainsmoking.  The value will be inserted directly as
an C<<< only >>> clause on your main DZIL C<<< .travis.yml >>> file.  The default is not set, so that it is
ran for all of your branches.

If you want to disable "after release" testing, because, say, you're using L<Travis::TestRelease|Dist::Zilla::Plugin::Travis::TestRelease>
to test things beforehand, you can restrict Travis to only test the release_testing branches:

    dzil_branch = /^release_testing\/.*/

=head2 notify_email

This affects the notification options of the resulting YML file.  It can either be set to:

=over

=item *

C<<< 0 >>> = Disable email notification

=item *

C<<< 1 >>> = Enable email notification, using Travis CI's default email scheme

=item *

C<<< foo@bar.com >>> (can be multiple; one per line) = Enable email notification to these email
addresses

=back

The default is C<<< 1 >>>.

=head2 notify_irc

This affects the notification options of the resulting YML file.  It can either be set to:

=over

=item *

C<<< 0 >>> = Disable IRC notification

=item *

C<<< 1 >>> = Enable IRC notification, using the C<<< IRC >>> or C<<< x_irc >>> meta resource value

=item *

C<<< irc://irc.perl.org/#roomname >>> (can be multiple; one per line) = Enable IRC notification
to these IRC serverE<sol>rooms

=back

The default is C<<< 0 >>>.  Please ask permission from the room channel operators before enabling
bot notification.

=head2 irc_template

Only applies when IRC notification is on.  The default is:

    %{branch}#%{build_number} by %{author}: %{message} (%{build_url})

This option can be specified more than once for multiple lines.  See L<Travis-CI's IRC notification docs|http://about.travis-ci.org/docs/user/notifications/#IRC-notification>
for a list of variables that can be used.

=head2 perl_version

This is a space-delimited option with a list of the perl versions to test against.  Versions can
be prepended with a dash to indicate that the version is allowed to fail.

The default is all of the major stable releases of Perl from 5.8 on up, including the
bleeding edge of Perl (called 'blead').  This works even if Travis doesn't actually carry
that version, thanks to Haarg's L<Perl Travis Helper tools|http://github.com/haarg/perl-travis-helper>,
used by this module to auto-install the right version of Perl via L<Perlbrew|http://perlbrew.pl/>.

Versions 5.8 and 'blead' are marked as "allowed to fail" versions.  The former is because
there are various DZIL plugins that require 5.10.  The latter because, well, it's bleeding
edge, and the tests may be failing because it's Perl's fault.

You can restrict it down to only a few like this:

    perl_version = 5.10 5.12 5.14.3 -5.8

Note that any custom settings here will prevent any newer versions from being auto-added (as this
distro is updated).

=head2 perl_version_build

This is just like C<<< perl_version >>>, except for build branches.  Both of these options are used in
dual DZIL+build YAML files as well.  (See the C<<< support_builddir >>> option for more details.)

The default is whatever C<<< perl_version >>> is set to.  You may want to force 5.8 to disallow failure:

    perl_version_build = 5.20 5.18 5.16 5.14 5.12 5.10 5.8

This, of course, requires that your module is compatible with 5.8.

=head2 mvdt

Turning this on enables L<Minimum Version Dependency Testing|Dist::Zilla::TravisCI::MVDT>.  This
will make your YML file less of a static file, as it will now include commands to forcefully
B<downgrade> your dependencies to the lowest version that your prereqs said they would be able
to use.

While going through the MVDT process is recommended, it can be a royal PITA sometimes, so this
option isn't on by default.  It's HIGHLY recommended that you read the above doc first to get an
idea of what you're diving into.

This applies to both YML files.

=head2 test_authordeps

Controls whether author dependencies will be tested while DZIL chainsmoking.  This option
is also directly linked to verbosity and parallelization of the author deps:

=over

=item *

C<<< 0 >>> = No tests or verbosity, all files are downloadedE<sol>installed in parallel (10 processes at a time)

=item *

C<<< 1 >>> = Each module is downloaded one at a time, tested, and with verbosity turned on

=back

The default is C<<< 0 >>>.

=head2 test_deps

Just like C<<< test_authordeps >>>, but for the real deps that the module needs.  This also affects
testing for build chainsmoking as well.

The default is C<<< 1 >>>.

=head2 support_builddir

Controls whether to build a dual DZIL+build YAML or a standard DZIL YAML.  This is different than a
build branch YAML, as that is solely used for build tests.

This new config would add a new env variable and double the number of Travis tests.  It is expected
that a build directory would be found in C<<< .build/testing >>>.  If it doesn't exist, the build tests
would essentially be a no-op.

This is used by L<Travis::TestRelease|Dist::Zilla::Plugin::Travis::TestRelease>'s release testing
branches, if its C<<< create_builddir >>> option is also turned on.  However, if you have some other
mechanism to dump the build release into that directory (and don't mind a combined DZIL+build master
branch), this option could be used to test that sort of branch.

Because it can make the config (and Travis tests) kind of messy if you're not using them, the default
is C<<< 0 >>>.

=head2 sudo

Tells Travis CI to use its faster to start container-based infrastrucure which only works with non-root
access. If you need root access then set this to C<<< 1 >>> and Travis CI will fall back to the tradional
infrastructure.

The default is C<<< 0 >>>.

=head2 Custom Commands

For the most part, the default command sets for TravisYML serves its purpose.  However, you may
have some unusual situation from within your distro that demands a custom command or two.  For
that purpose, there is a set of "dynamic" options available to add or replace any part of the
command list for Travis.

They are in the form of:

    $pos$phase$filetype
 
    $pos      = Either 'pre_' or 'post_' (optional)
    $phase    = One of the Travis-CI testing phases (required)
    $filetype = Either '_dzil' or '_build' (optional)

See L<Travis-CI's Build Lifecycle|http://docs.travis-ci.com/user/build-lifecycle/>
for a list of phases.

The positions determine if the commands are to be added at the beginning (C<<< pre_ >>>), the end (C<<< post_ >>>), or
replacing (no prefix) the existing code.  Replace entire blocks at your own risk; TravisYML may change
the original blocks for bug fixes or new features, and you wouldn't see them if they were replaced.

The file type determines if these command changes are for the DZIL YML file (C<<< _dzil >>>), the build YML file
(C<<< _build >>>), or both (no suffix).

For example, this would give you the following combinations for the 'before_install' phase:

    before_install            = Replace all before_install blocks
    pre_before_install        = Unshift lines to all before_install blocks
    post_before_install       = Push lines to all before_install blocks
    before_install_dzil       = Replace DZIL before_install block
    pre_before_install_dzil   = Unshift lines to DZIL before_install block
    post_before_install_dzil  = Push lines to DZIL before_install block
    before_install_build      = Replace build before_install block
    pre_before_install_build  = Unshift lines to build before_install block
    post_before_install_build = Push lines to build before_install block

These options are all multi-lined, so you can add as many commands as you need:

    pre_install_dzil = export AUTHOR_TESTING=1
    pre_install_dzil = echo "Author testing is now "$AUTHOR_TESTING

=head1 WHY USE THIS?

A common question I get with this plugin is: I<"If .travis.yml is a static file, why bother with a plugin?">

Three reasons:

1. B<DZIL and Travis-CI interactions> - If you look at the YML file itself, you'll notice that it's not a 5-line
file.  It's not as simple as telling Travis that this is a Perl distro and GO.  Both Travis-CI and DZIL are
ever changing platforms, and this plugin will keep things in sync with those two platforms.  (For example,
Travis VMs recently stopped using a valid nameE<sol>email for git's user.* config items, which impacted DZIL smoking
with certain Git plugins.  So, TravisYML had to compensate.)  I personally use this plugin myself, so if there
are new issues that come up, I should be one of the first to notice.

2. B<Build branches> - Build branches are great for having a perfect copy of your current release, giving non-DZIL
folks a chance to submit patches, and for running a Travis-CI test on something that is close to the CPAN
release as possible.  However, setting that up can be tricky, and it requires a second YML file just for the build
branch.  TravisYML manages that by hiding the DZIL C<<< .travis.yml >>> file prior to building, and then creating a new
one after release (but before the build branch is commited).

3. B<MVDT> - If you want to brave through the L<Minimum Version Dependency Testing|Dist::Zilla::TravisCI::MVDT>
process, this will automate the YML generation for you.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-TravisCI>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::TravisCI/>.

=head1 AUTHOR

Brendan Byrd <bbyrd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
