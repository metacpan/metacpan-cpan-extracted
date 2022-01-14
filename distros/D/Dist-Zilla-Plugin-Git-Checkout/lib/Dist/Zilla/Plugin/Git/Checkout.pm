package Dist::Zilla::Plugin::Git::Checkout;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.004';

use Moose;

with 'Dist::Zilla::Role::BeforeRelease';

use Git::Background 0.003;
use Git::Version::Compare ();
use MooseX::Types::Moose qw(Bool Str);
use Path::Tiny;
use Term::ANSIColor qw(colored);

use namespace::autoclean;

has branch => (
    is  => 'ro',
    isa => Str,
);

has dir => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { path( shift->repo )->basename('.git') },
);

has push_url => (
    is  => 'ro',
    isa => Str,
);

has repo => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has revision => (
    is  => 'ro',
    isa => Str,
);

has tag => (
    is  => 'ro',
    isa => Str,
);

has _is_dirty => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

my $BRANCH   = 'branch';
my $REVISION = 'revision';
my $TAG      = 'tag';

sub before_release {
    my ($self) = @_;

    return if !$self->_is_dirty;

    return if $self->zilla->chrome->prompt_yn(
        'Workspace ' . $self->dir . ' is dirty and was not updated. Release anyway?',
        { default => 0 },
    );

    $self->log_fatal('Aborting release');

    # should never be reached
    die 'Aborting release';    ## no critic (ErrorHandling::RequireCarping)
}

around plugin_from_config => sub {
    my ( $orig, $plugin_class, $name, $payload, $section ) = @_;

    my $instance = $plugin_class->$orig( $name, $payload, $section );

    $instance->_run;

    return $instance;
};

sub _checkout {
    my ( $self, $dir, $commitish ) = @_;

    # BRANCH (default: master)
    #  - check if branch matches, otherwise abort
    #  - git pull
    # TAG
    # - git fetch --tags -f
    # - git checkout TAG
    # REV
    # - git fetch --tags -f
    # - git checkout REVISION

    $self->log_fatal("Directory $dir exists but is not a Git repository") if !$dir->child('.git')->is_dir;

    my $git  = Git::Background->new($dir);
    my $repo = $self->repo;

    # check that the workspace is from the correct repository
    my $origin_f = $git->run( 'config', 'remote.origin.url' )->await;
    $self->log_fatal("Directory $dir is not a Git repository for $repo") if $origin_f->is_failed || ( $origin_f->stdout )[0] ne $repo;

    my $commitish_id = $commitish->{id};
    if ( $self->_commitish_is_branch($commitish) ) {
        if ( !defined $commitish_id ) {

            # no branch is specified, find the default branch ...
            my $origin_head_f = $git->run(qw(symbolic-ref -q --short refs/remotes/origin/HEAD))->await;
            if ( $origin_head_f->is_done ) {
                ($commitish_id) = $origin_head_f->stdout;
                if ( defined $commitish_id ) {
                    $commitish_id =~ s{ \A origin / }{}xsm;
                }
            }

            # ... or fall back to master
            if ( !defined $commitish_id || $commitish_id eq q{} ) {
                $commitish_id = 'master';
            }
        }

        # check if we are on correct branch
        my $head_f = $git->run(qw(symbolic-ref -q --short HEAD))->await;
        $self->log_fatal("Directory $dir is not on branch $commitish_id") if $head_f->is_failed || ( $head_f->stdout )[0] ne $commitish_id;
    }

    # check if the workspace is dirty - skip updates for a dirty workspace
    if ( $git->run( 'status', '--porcelain' )->stdout ) {
        $self->log( colored( "Git workspace $dir is dirty - skipping checkout", 'yellow' ) );
        $self->_is_dirty(1);
        return;
    }

    # update the workspace
    if ( $self->_commitish_is_branch($commitish) ) {
        $self->log("Pulling $repo in $dir");
        $git->run( 'pull', '--ff-only' )->get;
    }
    else {
        $self->log("Fetching $repo in $dir");
        $git->run( 'fetch', '--tags', '-f' )->get;

        $self->log("Checking out $commitish->{type} $commitish_id in $dir");
        $git->run( 'checkout', $commitish_id )->get;
    }

    return;
}

sub _clone {
    my ( $self, $dir, $commitish ) = @_;

    # BRANCH (default: master)
    #  - clone --branch branch
    # TAG
    #  - clone
    #  - checkout tag
    # REV
    #  - clone
    #  - checkout revision

    my $repo = $self->repo;

    # clone the repository and checkout the correct commitish
    if ( $self->_commitish_is_branch($commitish) ) {
        if ( defined $commitish->{id} ) {
            $self->log("Cloning $repo into $dir (branch $commitish->{id})");
            Git::Background->run( 'clone', '--branch', $commitish->{id}, $repo, $dir->stringify )->get;
        }
        else {
            $self->log("Cloning $repo into $dir");
            Git::Background->run( 'clone', $repo, $dir->stringify )->get;
        }
    }
    else {
        $self->log("Cloning $repo into $dir");
        Git::Background->run( 'clone', $repo, $dir->stringify )->get;

        $self->log("Checking out $commitish->{type} $commitish->{id} in $dir");
        Git::Background->run( 'checkout', $commitish->{id}, { dir => $dir } )->get;
    }

    return;
}

sub _commitish_is_branch {
    my ( $self, $commitish ) = @_;

    return 1 if $commitish->{type} eq $BRANCH;
    return;
}

sub _ensure_adequate_git {
    my ($self) = @_;

    # check that an adequate Git is available
    my $git_version = Git::Background->version;
    $self->log_fatal(q{No 'git' in PATH}) if !defined $git_version;

    # Find which tag contains a commit: git tag --contains revision
    #
    # https://stackoverflow.com/a/6978402/8173111
    # git status --porcelain, commit 6f15787, September 2009, git 1.7.0
    # https://github.com/git/git/commit/6f15787181a163e158c6fee1d79085b97692ac2f
    #
    # git symbolic-ref --short, commit b8b5290, March 2012, git 1.7.10
    # https://github.com/git/git/commit/b8b52907e386d064fb0303c08215d7b117d50ee9
    $self->log_fatal(q{Your 'git' is too old. At least Git 1.7.10 is needed.}) if !Git::Version::Compare::ge_git( $git_version, '1.7.10' );

    return;
}

sub _process_options {
    my ($self) = @_;

    # verify plugin options
    my $branch = $self->branch;
    my $rev    = $self->revision;
    my $tag    = $self->tag;

    my $num_options = grep { defined } ( $branch, $rev, $tag );
    $self->log_fatal(q{Only one of branch, revision, or tag can be specified}) if $num_options > 1;

    return { type => $BRANCH,   id => $branch } if defined $branch;
    return { type => $REVISION, id => $rev }    if defined $rev;
    return { type => $TAG,      id => $tag }    if defined $tag;
    return { type => $BRANCH,   id => undef };
}

sub _run {
    my ($self) = @_;

    # check an adequate git is installed
    $self->_ensure_adequate_git;

    # verify the options given to this plugin
    my $commitish = $self->_process_options;

    # clone or update the workspace
    my $dir = path( $self->zilla->root )->child( path( $self->dir ) )->absolute;
    if ( $dir->is_dir ) {
        $self->_checkout( $dir, $commitish );
    }
    else {
        $self->_clone( $dir, $commitish );
    }

    # update the push URL
    $self->_update_push_url($dir);

    return;
}

sub _update_push_url {
    my ( $self, $dir ) = @_;

    my $git = Git::Background->new($dir);

    # configure or remove the push url
    if ( defined $self->push_url ) {
        $git->run( 'remote', 'set-url', '--push', 'origin', $self->push_url )->get;
    }
    else {
        my $push_url_f = $git->run( 'config', 'remote.origin.pushurl' )->await;
        if ( $push_url_f->is_done ) {
            my ($push_url) = $push_url_f->stdout;

            if ( defined $push_url ) {
                $git->run( 'remote', 'set-url', '--delete', '--push', 'origin', $push_url )->get;
            }
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Checkout - clone and checkout a Git repository

=head1 VERSION

Version 0.004

=head1 SYNOPSIS

  # in dist.ini:
  [Git::Checkout]
  :version = 0.004
  repo = https://github.com/skirmess/dzil-inc.git

=head1 DESCRIPTION

This plugin clones, or if it is already cloned, fetches and updates a Git
repository.

The plugin runs during the initialization phase, which is the same for
bundles and plugins. You can check out a Git repository and load bundles
or plugins from this repository.

  # in dist.ini
  [Git::Checkout]
  :version = 0.004
  repo = https://github.com/skirmess/dzil-inc.git

  ; add the lib directory inside the checked out Git repository to @INC
  [lib]
  lib = dzil-inc/lib

  ; this bundle is run from inside the checked out Git repositories lib
  ; directory
  [@BundleFromRepository]

Git version 1.7.10 or later is required.

=head1 USAGE

=head2 branch / revision / tag

Available since version 0.004.

Specifies what to check out. This can be a branch, a tag or a revision.
Only one of these three options can be used.

If none is specified it defaults to the branch returned by

    git symbolic-ref -q --short refs/remotes/origin/HEAD

and if that doesn't exist to the branch C<master>.

=head2 dir

The repositories workspace is checked out into this directory. This defaults
to the basename of the repo without the C<.git> suffix.

=head2 push_url

Allows you to specify a different push url for the repositories origin. One
possible scenario would be if you would like to clone via https but push via
ssh. This is optional.

=head2 repo

Specifies the address of the repository to clone. This is required.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-Checkout/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-Checkout>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Git-Checkout.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2022 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla>, L<lib>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
