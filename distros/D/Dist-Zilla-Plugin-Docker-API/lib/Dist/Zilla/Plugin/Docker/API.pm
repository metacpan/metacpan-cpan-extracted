package Dist::Zilla::Plugin::Docker::API;
# ABSTRACT: Build and publish Docker images as Dist::Zilla release artifacts
our $VERSION = '0.105';
use Moose;
with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::BeforeBuild';
with 'Dist::Zilla::Role::AfterBuild';
with 'Dist::Zilla::Role::Releaser';

use namespace::autoclean;
use Log::Any qw($log);
use Path::Tiny;

use Dist::Zilla::Plugin::Docker::API::TagTemplate;
use Dist::Zilla::Plugin::Docker::API::Result;

# Primary attributes
has image => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    init_arg => 'image',
);

# Deprecated reader; the constructor key is funneled into image by BUILDARGS.
has repository => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    init_arg => undef,
    default  => sub { shift->image },
);

# The dist.ini key is 'dockerfile'. 'file' is the deprecated spelling and is
# funneled in by BUILDARGS -- it used to be the only one that worked, because
# this attribute carried init_arg => 'file' while the POD documented
# 'dockerfile'.
has dockerfile => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Dockerfile',
);

# Canonical tag attribute: one list, applied both at build (locally) and
# at release (pushed). Deprecated build_tag / release_tag funnel into here
# via BUILDARGS.
has tag => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_tag_default',
);

sub _build_tag_default { ['latest', '%V', '%v'] }

has build_arg => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has label => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has platform => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

# Release behavior
has release_push => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

# Deprecated reader; the constructor key is funneled into release_push.
has push => (
    is       => 'ro',
    isa      => 'Bool',
    lazy     => 1,
    init_arg => undef,
    default  => sub { shift->release_push },
);

# When false (default), the build log only echoes Dockerfile step headers
# (e.g. "Step 3/18 : RUN apt-get update", Podman's "STEP 3/18: ..." or
# BuildKit's "#5 [4/12] ..."),
# not the per-command output. Set to true for the full stream.
has build_verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has release_enabled => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

# Common options
has pull => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has no_cache => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has rm => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has force_rm => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has target => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
    init_arg => '_target',
);

has network_mode => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
    init_arg => '_network_mode',
);

has fail_if_tag_exists => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has skip_latest_on_trial => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has client_class => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Dist::Zilla::Plugin::Docker::API::Client',
);

has _tag_template => (
    is      => 'ro',
    isa     => 'Dist::Zilla::Plugin::Docker::API::TagTemplate',
    lazy    => 1,
    builder => '_build_tag_template',
);

has _client => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    builder => '_build_client',
);

sub _build_tag_template {
    my ($self) = @_;
    return Dist::Zilla::Plugin::Docker::API::TagTemplate->new(
        zilla     => $self->zilla,
        plugin_name => $self->plugin_name,
    );
}

sub _build_client {
    my ($self) = @_;
    my $client_class = $self->client_class;
    unless (eval "require $client_class; 1") {
        $self->log_fatal("Cannot load client_class $client_class: $@");
    }
    return $client_class->new(
        logger => sub { $self->log(@_) },
        logger_fatal => sub { $self->log_fatal(@_) },
    );
}

sub tag_template { shift->_tag_template }
sub client { shift->_client }

sub file { shift->dockerfile }

# API::Docker croaks through Carp, so a reason arrives carrying one or more
# " at FILE line N." tails. Strip all of them (not just the last) and flatten
# to a single line -- log_fatal repeats whatever it is given, and a
# multi-line message gets repeated in full.
sub _flatten_error {
    my ($self, $error) = @_;

    $error = '' unless defined $error;
    $error =~ s/\s+at\s+\S+\s+line\s+\d+\.?//g;
    $error =~ s/\s+/ /g;
    $error =~ s/^\s+|\s+$//g;
    return $error;
}

# after_build builds an image unconditionally, so every dzil command that
# builds needs a reachable engine. Ask for one up front instead of letting
# Dist::Zilla gather, munge and write out a whole distribution first and only
# then die on a socket that was never there.
sub before_build {
    my ($self) = @_;

    if ($ENV{DZIL_DOCKER_API_SKIP}) {
        $self->log('DZIL_DOCKER_API_SKIP is set: skipping the image build '
            .'for this run - no engine contact, no image');
        return;
    }

    # The classic /build endpoint takes exactly one platform; a second value
    # would otherwise be dropped without a word. This is configuration, not
    # engine contact, so DZIL_DOCKER_API_SKIP_PRECHECK does not skip it.
    my @platforms = @{ $self->platform };
    if (@platforms > 1) {
        $self->log_fatal('only one platform is supported, got '
            .scalar(@platforms).': '.join(', ', @platforms)
            .' - the /build endpoint takes exactly one platform, and this '
            .'plugin is not built for multi-arch images');
    }

    return if $ENV{DZIL_DOCKER_API_SKIP_PRECHECK};

    my $info = eval { $self->client->engine_info };
    my $error = $@;

    if ($error) {
        $error = $self->_flatten_error($error);

        $self->log('Docker::API speaks the Docker Engine HTTP API over a '
            .'socket and never shells out to the docker binary, so any engine '
            .'serving that API will do.');
        $self->log('Point DOCKER_HOST at one. For rootless Podman: '
            .'systemctl --user enable --now podman.socket, then '
            .'DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"');
        $self->log_fatal('cannot reach a container engine: '.$error
            .' (set DZIL_DOCKER_API_SKIP_PRECHECK=1 to skip this check)');
    }

    $self->log('Docker::API engine ready: '
        .($info->{engine} // 'unknown').' '
        .($info->{version} // '?')
        .' (API '.($info->{api_version} // '?').')');

    $self->_precheck_registry_auth
        if $ENV{DZIL_RELEASING} && $self->release_enabled && $self->release_push;
}

# A rejected or expired registry credential otherwise surfaces only when the
# push fails -- after Dist::Zilla gathered and wrote the distribution and
# after_build built and tagged the image, i.e. after the damage. This runs
# before any of it.
#
# The phase hook that runs early enough is before_build, and it can tell a
# release from a plain build: Dist::Zilla::Dist::Builder::release sets
# DZIL_RELEASING before it calls build_archive, so the variable is already
# there when this hook runs (measured against Dist::Zilla 6.037). A plain
# dzil build never sets it and so never needs registry credentials.
#
# Only the registry host of `image` decides which credential applies, and
# that part carries no template variables, so no expansion is needed here.
sub _precheck_registry_auth {
    my ($self) = @_;

    my $image_ref = $self->image;

    my $status = eval { $self->client->verify_auth_for_image_ref($image_ref) };
    my $error = $@;

    # Deliberately not worded as "rejected": the engine answers a bad
    # credential and an unreachable registry with the same failure -- Podman
    # returns 500 for both, so the status cannot tell them apart. The engine's
    # own text, which does, is carried through verbatim.
    if ($error) {
        $self->log_fatal('the registry credential check for '.$image_ref
            .' failed: '.$self->_flatten_error($error)
            .' (set DZIL_DOCKER_API_SKIP_PRECHECK=1 to skip this check)');
    }

    # No credential found for that registry. An anonymous push is a legal
    # thing to attempt, so this is a note, not a failure.
    unless (defined $status) {
        $self->log('Docker::API: no registry credentials found for '
            .$image_ref.' - the release push will be anonymous');
        return;
    }

    $self->log('Docker::API registry credentials accepted for '.$image_ref);
}

sub after_build {
    my ($self, $arg) = @_;

    return if $ENV{DZIL_DOCKER_API_SKIP};

    $self->log("Docker::API building image");

    my $build_root = $arg->{build_root};
    my $zilla = $self->zilla;

    my %tmpl_vars = $self->_template_vars($build_root, undef, $arg->{archive});

    my @image_refs = $self->_resolve_tags($self->tag, %tmpl_vars);
    my %labels = $self->_resolve_labels(%tmpl_vars);
    my %build_args = $self->_resolve_build_args(%tmpl_vars);

    my $context_path = Path::Tiny->new($build_root // $self->zilla->root);
    unless ($context_path->child($self->dockerfile)->exists) {
        $self->log_fatal("Dockerfile '" . $self->dockerfile
            . "' not found in build context: $context_path");
    }
    my $context_tar = {
        type       => 'dir',
        path       => $context_path->stringify,
    };

    my @platforms = @{ $self->platform };

    my $result = $self->client->build_image(
        context_tar  => $context_tar,
        dockerfile   => $self->dockerfile,
        tags         => \@image_refs,
        labels       => \%labels,
        buildargs    => \%build_args,
        pull         => $self->pull,
        nocache      => $self->no_cache,
        rm           => $self->rm,
        forcerm      => $self->force_rm,
        target       => $self->target,
        network_mode => $self->network_mode,
        platform     => $platforms[0],
        verbose      => $self->build_verbose,
    );

    $self->_log_build_result($result);
}

sub release {
    my ($self, $archive) = @_;

    # A skipped build phase means there is no image to tag and push. Refusing
    # here beats releasing a dist whose containers silently never shipped.
    $self->log_fatal('DZIL_DOCKER_API_SKIP is set: refusing to release '
        .'- the image build was skipped, there is nothing to push')
        if $ENV{DZIL_DOCKER_API_SKIP};

    # Skip if release is disabled
    return unless $self->release_enabled;

    # If no tags configured, skip
    return unless @{$self->tag};

    $self->log("Docker::API release: tagging and " . ($self->release_push ? "pushing" : "tagging only"));

    my $zilla = $self->zilla;
    my %tmpl_vars = $self->_template_vars($zilla->root, $zilla->version, $archive);

    my @tags = @{ $self->tag };

    if ($self->skip_latest_on_trial && $zilla->is_trial) {
        @tags = grep { $_ ne 'latest' } @tags;
        $self->log("Skipping 'latest' tag for trial release");
    }

    # Source image: first tag from the build phase (same list, resolved
    # via the same template). Build must have happened before release.
    my $source_image_ref = $self->image . ':' . $self->tag_template->expand($self->tag->[0], %tmpl_vars);

    # Check if the tag exists on the remote (if we're going to push), before
    # anything is tagged or pushed.
    #
    # "This engine cannot answer" is fatal here, not a warning. Whoever sets
    # fail_if_tag_exists asked for the tag to be protected; downgrading an
    # unanswerable check to a silent "does not exist" is exactly the bug this
    # replaces. An engine without a /distribution route -- rootless Podman --
    # therefore stops the release and says so.
    if ($self->release_push && $self->fail_if_tag_exists) {
        for my $tag (@tags) {
            my $image_ref = $self->_image_ref($tag, %tmpl_vars);
            my $exists = eval { $self->client->remote_tag_exists($image_ref) };
            my $error = $@;

            if ($error) {
                $self->log_fatal('fail_if_tag_exists is set, but this engine '
                    ."cannot answer whether '$image_ref' already exists on the "
                    .'remote registry: '.$self->_flatten_error($error)
                    .' - set fail_if_tag_exists = 0 to release without the check');
            }

            if ($exists) {
                $self->log_fatal("Tag '$tag' already exists on remote registry"
                    ." ($image_ref)");
            }
        }
    }

    # Tag existing image with release tags. If the source image is missing
    # (build never ran, or someone pruned the daemon), the underlying
    # Docker API will return a real 404 — surface that as a fatal error
    # instead of fabricating our own pre-check.
    my @image_refs = $self->_resolve_tags(\@tags, %tmpl_vars);
    for my $target_ref (@image_refs) {
        next if $target_ref eq $source_image_ref;
        eval {
            $self->client->tag_image(source => $source_image_ref, target => $target_ref);
        };
        if ($@) {
            $self->log_fatal("Failed to tag '$source_image_ref' as '$target_ref': $@");
        }
        $self->log("Tagged: $target_ref");
    }

    # Push if enabled
    if ($self->release_push) {
        my @failed;
        for my $image_ref (@image_refs) {
            $self->log("Pushing $image_ref...");
            eval {
                $self->client->push_image(image_ref => $image_ref);
            };
            if ($@) {
                $self->log("Warning: failed to push $image_ref: $@");
                push @failed, $image_ref;
            }
        }
        if (@failed) {
            $self->log_fatal("Push failed for: " . join(', ', @failed));
        }
    }
}

sub _template_vars {
    my ($self, $build_root, $version, $archive) = @_;
    my $zilla = $self->zilla;

    my $git = $self->_git_info;

    my %vars = (
        name          => $zilla->name,
        version       => $version // $zilla->version // '0',
        trial         => ($zilla->is_trial ? '-TRIAL' : ''),
        git_short_sha => $git->{short_sha} // '',
        git_full_sha  => $git->{full_sha} // '',
        branch        => $git->{branch} // '',
        build_root    => $build_root // '',
        source_root   => $zilla->root // '',
        archive       => $archive // '',
        plugin_name   => $self->plugin_name,
    );

    return %vars;
}

sub _git_info {
    my ($self) = @_;
    return $self->{_git_info} //= do {
        my $root   = $self->zilla->root;
        my $sha    = _git_capture($root, 'rev-parse', 'HEAD');
        my $branch = _git_capture($root, 'rev-parse', '--abbrev-ref', 'HEAD');

        my $full   = ($sha =~ /^([a-f0-9]{40})$/) ? $1 : '';
        my $br     = ($branch ne '' && $branch ne 'HEAD') ? $branch : '';

        {
            full_sha  => $full,
            short_sha => $full ? substr($full, 0, 7) : '',
            branch    => $br,
        };
    };
}

sub _git_capture {
    my ($dir, @cmd) = @_;
    my $pid = open(my $fh, '-|');
    return '' unless defined $pid;
    if ($pid == 0) {
        chdir $dir or exit 1;
        open STDERR, '>', '/dev/null';
        exec 'git', @cmd;
        exit 127;
    }
    my $out = do { local $/; <$fh> } // '';
    close $fh;
    return '' if $? != 0;
    chomp $out;
    return $out;
}

sub _resolve_tags {
    my ($self, $tags, %vars) = @_;
    return map { $self->_image_ref($_, %vars) } @{$tags};
}

sub _image_ref {
    my ($self, $tag, %vars) = @_;
    my $expanded = $self->tag_template->expand($tag, %vars);
    return $self->image . ':' . $expanded;
}

sub _resolve_labels {
    my ($self, %vars) = @_;
    my %labels;
    for my $label_def (@{ $self->label }) {
        if ($label_def =~ /^([^=]+)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            $labels{$key} = $self->tag_template->expand($value, %vars);
        }
    }
    return %labels;
}

sub _resolve_build_args {
    my ($self, %vars) = @_;
    my %args;
    for my $arg_def (@{ $self->build_arg }) {
        if ($arg_def =~ /^([^=]+)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            $args{$key} = $self->tag_template->expand($value, %vars);
        }
    }
    return %args;
}

sub _log_build_result {
    my ($self, $result) = @_;
    if ($result->image_id) {
        $self->log("Built image: " . $result->image_id);
    }
    if (@{ $result->tags }) {
        $self->log("Tagged: " . join(', ', @{ $result->tags }));
    }
    if (@{ $result->pushed }) {
        $self->log("Pushed: " . join(', ', @{ $result->pushed }));
    }
    if ($result->digest) {
        $self->log("Digest: " . $result->digest);
    }
    if (@{ $result->warnings }) {
        for my $warning (@{ $result->warnings }) {
            $self->log("Warning: $warning");
        }
    }
}

# Deprecated one-to-one spellings, old key => canonical key. These used to be
# declared as lazy attributes reading *from* the canonical one, which meant
# setting them in dist.ini changed nothing at all: 'push = 0' left
# release_push at 1 and the code reads release_push. They are funneled here instead, like
# build_tag/release_tag, so they actually take effect.
my %DEPRECATED_KEY = (
    file       => 'dockerfile',
    push       => 'release_push',
    repository => 'image',
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args = $class->$orig(@args);

    for my $old (sort keys %DEPRECATED_KEY) {
        next unless exists $args->{$old};
        my $new   = $DEPRECATED_KEY{$old};
        my $value = delete $args->{$old};

        if (exists $args->{$new}) {
            warn "[Docker::API] '".$old."' is deprecated and '".$new
               ."' is set explicitly; ignoring '".$old."'.\n";
            next;
        }

        warn "[Docker::API] '".$old."' is deprecated; use '".$new."' instead.\n";
        $args->{$new} = $value;
    }

    # Keys that no longer mean anything -- there is no switch behind them.
    # Drop them with a warning rather than letting an unknown key be silently
    # ignored.
    for my $removed (qw(build_load load phase release_load)) {
        next unless exists $args->{$removed};
        delete $args->{$removed};
        warn "[Docker::API] '".$removed."' is no longer supported and has no effect.\n";
    }

    my @legacy = grep { exists $args->{$_} } qw(build_tag release_tag);
    if (@legacy) {
        warn "[Docker::API] '" . join("' and '", @legacy)
           . "' are deprecated; use 'tag' instead.\n"
           . "  They are merged into 'tag' for now and will be removed in a future release.\n";

        my @merged;
        push @merged, @{ delete $args->{build_tag} // [] };
        push @merged, @{ delete $args->{release_tag} // [] };

        if (exists $args->{tag}) {
            warn "[Docker::API] 'tag' is set explicitly; ignoring deprecated build_tag/release_tag values.\n";
        }
        else {
            my %seen;
            $args->{tag} = [ grep { !$seen{$_}++ } @merged ];
        }
    }

    return $args;
};

sub mvp_multivalue_args { qw(tag build_tag release_tag build_arg label platform) }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Docker::API - Build and publish Docker images as Dist::Zilla release artifacts

=head1 VERSION

version 0.105

=head1 SYNOPSIS

    [Docker::API]
    image = ghcr.io/example/my-app

    tag = latest
    tag = %V
    tag = %v

    dockerfile = Dockerfile

    release_push = 1

Or via the L<@Author::GETTY|Dist::Zilla::PluginBundle::Author::GETTY> bundle:

    [@Author::GETTY::Docker / runtime]
    image = ghcr.io/example/my-app
    tags  = latest %V %v

=head1 DESCRIPTION

This plugin builds and publishes Docker images as release artifacts derived from
the Dist::Zilla-built distribution.

=head1 BEHAVIOR

| Dzil command | Docker behavior |
|---|---|
| C<dzil build>   | Build image, apply every C<tag>, no push |
| C<dzil release> | Re-tag the built image with every C<tag>, push (if C<release_push=1>) |

The same C<tag> list is used in both phases — C<dzil build> produces local tags
for verification, C<dzil release> re-applies them (against the already-built
image) and pushes if configured.

=head1 CONTAINER ENGINE

Builds and pushes go through L<API::Docker>, which speaks the Docker Engine
HTTP API over a socket. No C<docker> binary is involved at any point, so any
engine serving that API will do, and Docker itself need not be installed.
Podman's rootless socket is a tested alternative:

    systemctl --user enable --now podman.socket
    export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

C<target> reaches the engine unchanged, so the multi-stage builds this plugin
is usually pointed at behave the same either way.

The socket is located from C<DOCKER_HOST>, falling back to
C</var/run/docker.sock> and nothing else. Docker contexts are not consulted, so
a daemon selected with C<docker context use> will not be picked up here; set
C<DOCKER_HOST> in the environment C<dzil> runs in. See
L<API::Docker/CONTAINER ENGINES> for how that compares to other clients.

=head2 Startup precheck

Because C<after_build> builds an image unconditionally, every C<dzil> command
that builds needs a reachable engine. The plugin therefore asks the engine for
its version in C<before_build>, before Dist::Zilla gathers a single file, and
gives up there if nothing answers -- rather than letting a whole distribution
be assembled and only then dying on a socket that was never there.

On success the engine is named in the build log:

    [Docker::API] Docker::API engine ready: Podman Engine 5.4.2 (API 1.41)

Set C<DZIL_DOCKER_API_SKIP_PRECHECK=1> to skip the check and get the previous
behaviour back, where an unreachable engine only surfaces once the build
reaches the image. With several C<Docker::API> plugins in one F<dist.ini>,
each runs its own precheck.

When C<before_build> runs as part of C<dzil release> (Dist::Zilla sets
C<DZIL_RELEASING> before it calls C<build_archive>, which is early enough to
tell a release from a plain build) and both C<release_enabled> and
C<release_push> are true, the same hook also pre-flights the registry
credential the eventual push would use -- resolved as described in
L</"Registry credentials"> below -- and hands it to the engine's
C<POST /auth> (C<< system->auth >>) before anything is built. A plain
C<dzil build> never triggers this and needs no registry credentials at all.
No credential resolved for the registry is not a failure -- an anonymous push
is a legal thing to attempt, so nothing is checked and nothing fails. A
failed check is fatal, before the build starts, and its message says only
that the check failed, not that the credential was rejected: Podman answers
a rejected credential and an unreachable registry with the same C<500>, so
the two cannot be told apart from the status alone, and the engine's own
text is included instead.

C<DZIL_DOCKER_API_SKIP_PRECHECK=1> skips this credential check along with the
engine version probe above.

Set C<DZIL_DOCKER_API_SKIP=1> to skip the image build entirely for one run --
no engine contact, no image, one loud log line per plugin. This is for local
C<dzil build> / C<dzil install> / C<dzil test> while the image cannot build
yet, for example while a dependency pinned in the F<Dockerfile>'s C<cpanm>
run is not released. C<dzil release> refuses to run with the variable set:
a skipped build phase means there is no image to tag and push.

=head2 Registry credentials

The release push, the C<fail_if_tag_exists> lookup and the registry
credential precheck above all resolve a credential for an image reference
the same way, through C<auth_for_image_ref>, which walks an ordered list of
candidate auth files rather than reading a single one. For the registry the
image reference names, the first candidate file with a usable entry for it
wins; a file with none falls through to the next, so a Docker config and a
Podman auth file can each supply credentials for different registries in
the same run. In order: C<REGISTRY_AUTH_FILE>, if set, names the file
directly; then F<config.json> in the directory named by C<DOCKER_CONFIG>,
if set; then F<$XDG_RUNTIME_DIR/containers/auth.json>, if
C<XDG_RUNTIME_DIR> is set; then F<containers/auth.json> under
C<XDG_CONFIG_HOME> (or under F<~/.config> when that is unset); and finally
F<~/.docker/config.json>. F<~/.dockercfg>, Docker's legacy
pre-C<config.json> format, is never read.

All five files share the same C<auths> block, so once a file is chosen the
selection within the matching registry's entry does not depend on which one
supplied it. The first of these present wins: an
C<identitytoken>; a base64 C<auth> field decoded to C<username:password>;
plain C<username> / C<password> fields. Docker Hub is matched under any of
C<https://index.docker.io/v1/> and C<v2/>, C<index.docker.io> or
C<docker.io>. A C<credsStore> or C<credHelpers> entry that delegates the
secret to an external helper is not supported -- nothing in this plugin
reads either key, so such a registry resolves to no credential and any
request against it goes out anonymous rather than failing.

A plain C<docker login> or C<podman login> is now picked up with no extra
configuration: Podman's own default auth file is candidate three above. If
C<podman login --authfile PATH> was used to write somewhere else, set
C<REGISTRY_AUTH_FILE=PATH> in the environment C<dzil> runs in so candidate
one finds it.

Finding no credential for a registry is never an error by itself in this
plugin -- both C<fail_if_tag_exists> and the release push treat it as "go
anonymous," and only a credential that C<auth_for_image_ref> did find and
the engine then rejects (or an unreachable registry -- see above) is fatal.

=head1 CONFIGURATION

=over 4

=item C<image> - Full image repository (required). Example: C<ghcr.io/user/my-app>

=item C<tag> - Tags applied to the image (can be repeated, template-enabled).
Default: C<latest>, C<%V>, and C<%v> (e.g. C<latest>, C<0>, C<0.402>).
Applied identically in both build and release. Note: setting C<tag>
explicitly B<replaces> the default list, it does not append to it.

=item C<dockerfile> - Dockerfile name (default: C<Dockerfile>)

=item C<release_push> - Push to registry during release (default: true)

=item C<build_verbose> - When false (default), the build log only echoes
Dockerfile step headers — the legacy builder format C<Step N/M : ...>,
Podman's classic builder C<STEP N/M: ...> and BuildKit's C<#N [N/M] ...> —
instead of the full per-command output.
Set to true to see every line the daemon streams back. Errors are always
surfaced regardless of this flag.

=item C<fail_if_tag_exists> - Abort the release if any tag already exists on
the remote registry (default: false). The check runs before anything is
tagged or pushed, and only when C<release_push> is also true. It asks the
I<registry>, not the local daemon, through C<API::Docker>'s
C<< distribution->exists >> (C<GET /distribution/{name}/json>), using the
credential resolved for C<image> (see L</"Registry credentials">), or an
anonymous request when none applies.

An engine that has no C</distribution> route -- rootless Podman among them --
cannot answer the question at all, and that is treated as a release-stopping
failure rather than as "the tag is free": the release aborts with the
engine's own error and a reminder that C<fail_if_tag_exists = 0> releases
without the check.

=item C<skip_latest_on_trial> - Skip C<latest> tag for trial releases

=item C<build_arg> - Build arguments (can be repeated, template-enabled)

=item C<label> - OCI labels (can be repeated, template-enabled)

=item C<platform> - Target platform, exactly one (e.g. C<linux/arm64>). The key
is repeatable only so that a second value is refused with a clear error: the
/build endpoint takes one platform, and this plugin is not built for multi-arch
images.

=back

=head1 DEPRECATED

The following names are still accepted but emit a warning and will be removed
in a future release. Each is funneled into its canonical attribute by
C<BUILDARGS>; where both spellings are given, the canonical one wins and the
collision is reported.

=over 4

=item C<file> - Use C<dockerfile> instead.

Until 0.104 this was the only spelling that worked: the attribute carried
C<< init_arg => 'file' >> while the documentation described C<dockerfile>, so
C<dockerfile = ...> in a F<dist.ini> was silently ignored and the default
F<Dockerfile> used instead. C<dockerfile> is now the canonical key.

=item C<build_tag>, C<release_tag>

Replaced by the single C<tag> attribute. When either is given, the values are
merged (build_tag first, release_tag second) into C<tag> and a deprecation
warning is emitted. If C<tag> is also set explicitly, it wins and the legacy
values are ignored.

=item C<repository> - Use C<image> instead.

=item C<push> - Use C<release_push> instead.

=back

Note that C<repository> and C<push> did B<not> work as aliases before
0.104: they were declared as readers taking their value I<from> the canonical
attribute, so setting one in a F<dist.ini> had no effect whatsoever. They are
funneled properly now.

=head1 REMOVED

These keys are no longer supported. Each is warned about and discarded; none
has a replacement.

=over 4

=item C<phase> - The build and release phases are implicit.

=item C<build_load>, C<release_load>, C<load> - The image is built through the
engine API, where it lands in the engine's image store regardless, so there is
nothing left to switch.

=back

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Docker::API::TagTemplate>,
L<Dist::Zilla::Plugin::Docker::API::Client>,
L<Dist::Zilla::Plugin::Docker::API::Result>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-dist-zilla-plugin-docker-api/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
