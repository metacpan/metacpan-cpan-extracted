package Dist::Zilla::Plugin::Docker::API::Client;
# ABSTRACT: Thin adapter around API::Docker
our $VERSION = '0.105';
use Moo;
use Archive::Tar;
use Archive::Tar::Constant ();
use Carp qw( croak );
use Path::Tiny;
use JSON::MaybeXS qw( decode_json );
use MIME::Base64 qw( decode_base64 );

use API::Docker;
use Dist::Zilla::Plugin::Docker::API::Result;

has docker => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        API::Docker->new;
    },
);

has logger => (
    is       => 'ro',
    required => 1,
);

has logger_fatal => (
    is       => 'ro',
    required => 1,
);

# A single explicit auth file. The historical seam: setting it overrides the
# whole discovery list below with just this one file. The @Author::GETTY::Docker
# bundle never sets it; the below-seam tests inject a fixture through it.
has docker_config_path => (
    is        => 'ro',
    predicate => 'has_docker_config_path',
);

# The ordered list of auth files to consult, most specific first. Podman's
# auth.json and Docker's config.json share the same {"auths":{...}} format, so
# one list covers both engines. A set docker_config_path replaces the list;
# an empty/unset env var simply drops its stage. ~/.dockercfg (legacy) is left
# out on purpose.
has auth_file_candidates => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        return [ $self->docker_config_path ] if $self->has_docker_config_path;

        my @candidates;

        # 1. REGISTRY_AUTH_FILE points straight at the file (podman's override).
        push @candidates, Path::Tiny::path($ENV{REGISTRY_AUTH_FILE})
            if defined $ENV{REGISTRY_AUTH_FILE} && length $ENV{REGISTRY_AUTH_FILE};

        # 2. $DOCKER_CONFIG/config.json
        push @candidates, Path::Tiny::path($ENV{DOCKER_CONFIG}, 'config.json')
            if defined $ENV{DOCKER_CONFIG} && length $ENV{DOCKER_CONFIG};

        # 3. $XDG_RUNTIME_DIR/containers/auth.json (podman's live login store).
        push @candidates, Path::Tiny::path($ENV{XDG_RUNTIME_DIR}, 'containers', 'auth.json')
            if defined $ENV{XDG_RUNTIME_DIR} && length $ENV{XDG_RUNTIME_DIR};

        # 4. $XDG_CONFIG_HOME/containers/auth.json, falling back to ~/.config.
        my $config_home = (defined $ENV{XDG_CONFIG_HOME} && length $ENV{XDG_CONFIG_HOME})
            ? $ENV{XDG_CONFIG_HOME}
            : Path::Tiny::path($ENV{HOME} // '', '.config');
        push @candidates, Path::Tiny::path($config_home, 'containers', 'auth.json');

        # 5. ~/.docker/config.json (classic docker location).
        push @candidates, Path::Tiny::path($ENV{HOME} // '', '.docker', 'config.json');

        return \@candidates;
    },
);

# Parsed auth files, in candidate order. Missing, unreadable or unparseable
# files are skipped (a parse error warns, as before, then falls through), so
# the list holds only the configs that actually yielded JSON.
has _auth_configs => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        my @configs;
        for my $path (@{ $self->auth_file_candidates }) {
            next unless $path;
            my $file = Path::Tiny::path($path);
            next unless -r "$file";
            my $data = eval { decode_json($file->slurp_utf8) };
            if ($@ || !$data) {
                $self->logger->("Warning: cannot parse $file: $@") if $@;
                next;
            }
            push @configs, $data;
        }
        return \@configs;
    },
);

# Cheapest round trip that proves an engine is actually listening on the
# socket. Used by the plugin's before_build precheck, so a missing daemon
# is reported before Dist::Zilla does any work rather than after.
sub engine_info {
    my ($self) = @_;

    my $version = eval { $self->docker->system->version };
    croak $@ if $@;
    croak 'the engine returned no version information'
        unless ref $version eq 'HASH';

    my ($engine) = grep { ($_->{Name} // '') =~ /engine/i }
        @{ $version->{Components} // [] };

    return {
        version     => $version->{Version},
        api_version => $version->{ApiVersion},
        engine      => $engine ? $engine->{Name} : undef,
    };
}

# The engine's tag endpoint takes the repository and the tag as two separate
# parameters (POST /images/{name}/tag?repo=&tag=), so a full image reference
# has to be taken apart before it goes over the wire. Passing the whole thing
# as `repo` leaves `tag` empty and the engine fills in its own default:
# podman then rejects `example/app:1.0:latest` with a 500 and every version
# tag is quietly lost. Splitting happens here rather than in API::Docker,
# which mirrors the endpoint and should keep doing so.
sub _split_image_ref {
    my ( $self, $ref ) = @_;

    my $colon = rindex $ref, ':';
    return ( $ref, undef ) if $colon < 0;
    # A colon before the last slash belongs to a registry host:port, not to a
    # tag: registry.example.com:5000/team/app carries no tag at all.
    return ( $ref, undef ) if rindex($ref, '/') > $colon;

    return ( substr($ref, 0, $colon), substr($ref, $colon + 1) );
}

sub build_image {
    my ($self, %arg) = @_;

    my $context = $arg{context_tar};
    my $dockerfile = $arg{dockerfile} // 'Dockerfile';
    my @tags = @{ $arg{tags} // [] };
    my %labels = %{ $arg{labels} // {} };
    my %buildargs = %{ $arg{buildargs} // {} };
    my $pull = $arg{pull} // 0;
    my $nocache = $arg{nocache} // 0;
    my $rm = $arg{rm} // 1;
    my $forcerm = $arg{forcerm} // 1;
    my $target = $arg{target};
    my $network_mode = $arg{network_mode};
    my $platform = $arg{platform};
    my $verbose = $arg{verbose} // 0;

    my $docker = $self->docker;

    my %build_opts = (
        dockerfile => $dockerfile,
        t => @tags ? $tags[0] : undef,
        pull => $pull ? 1 : 0,
        nocache => $nocache ? 1 : 0,
        rm => $rm ? 1 : 0,
        forcerm => $forcerm ? 1 : 0,
    );

    $build_opts{labels} = \%labels if %labels;
    $build_opts{buildargs} = \%buildargs if %buildargs;
    $build_opts{target} = $target if defined $target && length $target;
    $build_opts{networkmode} = $network_mode if defined $network_mode && length $network_mode;
    $build_opts{platform} = $platform if defined $platform && length $platform;

    my $image_id;
    my @processed_tags;

    # Concise mode (default): only forward Dockerfile step headers — both the
    # legacy builder ("Step N/M : ...") and BuildKit ("#N [N/M] ..."). Skip the
    # noisy intermediate container chatter. Verbose mode forwards every line.
    # The line buffer is used in both modes so the Dist::Zilla logger (which
    # appends its own newline) doesn't get a stream chunk with a trailing \n.
    my $line_buf = '';
    my $progress_cb = sub {
        my ($event) = @_;
        if ($event->{errorDetail}) {
            $self->logger_fatal->("Docker build error: " . $event->{errorDetail}{message});
        }
        elsif (defined $event->{stream}) {
            for my $line ($self->_extract_build_lines(\$line_buf, $event->{stream}, $verbose)) {
                $self->logger->($line);
            }
        }
        elsif ($event->{progress}) {
            $self->logger->($event->{status} . ' ' . $event->{progress}) if $verbose;
        }
        if ($event->{aux} && $event->{aux}{ID}) {
            $image_id = $event->{aux}{ID};
        }
    };

    my $tarball;
    if (ref($context) eq 'HASH') {
        if ($context->{type} eq 'dir') {
            $tarball = $self->_create_tar($context->{path});
        }
        elsif ($context->{type} eq 'archive') {
            $tarball = Path::Tiny::path($context->{path})->slurp_raw;
        }
        else {
            $self->logger_fatal->("Unknown context type: " . ($context->{type} // 'undef'));
        }
    }
    else {
        $tarball = $context;
    }

    eval {
        my $events = $docker->images->build(
            context => $tarball,
            %build_opts,
        );

        for my $event (@{$events // []}) {
            $progress_cb->($event);
        }
    };

    if (my $err = $@) {
        # API::Docker 0.003 croaks on the errorDetail event before the loop
        # above gets to run, so the output that led up to the failure rides
        # on the exception instead. Drain it from there, or a failed build
        # logs nothing but the last line (api-docker #12). The error event
        # itself is left out: the reason arrives through the fatal below.
        if (ref $err && $err->can('events')) {
            $progress_cb->($_) for grep { !$_->{errorDetail} } @{ $err->events };
        }
        $self->logger_fatal->("Docker build failed: $err");
    }

    for my $tag (@tags) {
        next if $tag eq ($tags[0] // '');
        my ( $repo, $tag_name ) = $self->_split_image_ref($tag);
        eval {
            $docker->images->tag($image_id,
                repo => $repo,
                defined $tag_name ? ( tag => $tag_name ) : (),
            );
        };
        if ($@) {
            $self->logger->("Warning: failed to tag image as $tag: $@");
            next;
        }
        push @processed_tags, $tag;
    }

    return Dist::Zilla::Plugin::Docker::API::Result->new(
        image_id => $image_id,
        tags     => \@processed_tags,
        pushed   => [],
    );
}

sub _extract_build_lines {
    my ($self, $buf_ref, $chunk, $verbose) = @_;
    $$buf_ref .= $chunk;
    my @out;
    while ($$buf_ref =~ s/^([^\n]*)\n//) {
        my $line = $1;
        next unless length $line;
        if ($verbose) {
            push @out, $line;
        }
        elsif ($self->_is_build_step_header($line)) {
            push @out, $line;
        }
    }
    return @out;
}

sub _is_build_step_header {
    my ($self, $line) = @_;
    return 0 unless defined $line && length $line;
    # Legacy builder: "Step 3/18 : RUN apt-get update"
    return 1 if $line =~ m{^Step \s+ \d+/\d+ \s* :}x;
    # Podman classic builder: "STEP 3/18: RUN apt-get update"
    return 1 if $line =~ m{^STEP \s+ \d+/\d+ \s* :}x;
    # BuildKit stage header: "#5 [4/12] RUN apt-get update"
    return 1 if $line =~ m{^\#\d+ \s+ \[\d+/\d+\]}x;
    # BuildKit named stage: "#7 [builder 3/8] COPY . ."
    return 1 if $line =~ m{^\#\d+ \s+ \[[^\]]+ \s+ \d+/\d+\]}x;
    return 0;
}

# The whole directory as a tar. Which file in it is the Dockerfile is the
# engine's business: build_image passes that as its own dockerfile option.
sub _create_tar {
    my ($self, $dir) = @_;

    my $root = Path::Tiny::path($dir);
    my $tar  = Archive::Tar->new;

    for my $entry ($self->_collect_files($root, $root)) {
        my $name = $entry->relative($root)->stringify;
        my @stat = lstat $entry->stringify;
        my %opt  = ( mode => $stat[2] & 07777, mtime => $stat[9] );

        if (-l $entry->stringify) {
            $tar->add_data($name, '', {
                %opt, type => Archive::Tar::Constant::SYMLINK(),
                linkname => readlink($entry->stringify),
            });
        }
        elsif (-d _) {
            $tar->add_data($name, '', { %opt, type => Archive::Tar::Constant::DIR() });
        }
        else {
            $tar->add_data($name, $entry->slurp_raw, \%opt);
        }
    }

    my $tarball;
    open my $fh, '>', \$tarball;
    $tar->write($fh, 1);
    close $fh;

    return \$tarball;
}

# Regular files, symlinks (never followed) and empty directories below $dir.
sub _collect_files {
    my ($self, $root, $dir) = @_;

    my @files;
    for my $entry ($dir->children) {
        if (-l $entry->stringify) {
            push @files, $entry;
        }
        elsif ($entry->is_dir) {
            my @below = $self->_collect_files($root, $entry);
            push @files, @below ? @below : $entry;
        }
        else {
            push @files, $entry;
        }
    }
    return @files;
}

sub auth_for_image_ref {
    my ($self, $image_ref) = @_;
    my $registry = $self->_registry_for_image_ref($image_ref);
    # Walk the parsed auth files in order and run the per-file registry
    # selection against each. The first file with a usable entry for this
    # registry wins; a file that has none falls through to the next, so a
    # docker config.json and a podman auth.json can each supply credentials
    # for different registries.
    for my $config (@{ $self->_auth_configs }) {
        my $auth = $self->_auth_for_registry($registry, $config);
        return $auth if defined $auth;
    }
    return undef;
}

sub _registry_for_image_ref {
    my ($self, $image_ref) = @_;

    # Strip ":tag" or "@sha256:..." suffix from the image part.
    my $name = $image_ref;
    $name =~ s/\@sha256:.*$//;
    my @parts = split m{/}, $name;

    # If the first component does NOT look like a registry host
    # (no dot, no colon, not "localhost"), it's an implicit Docker Hub repo.
    if (@parts < 2 || ($parts[0] !~ /[.:]/ && $parts[0] ne 'localhost')) {
        return 'https://index.docker.io/v1/';
    }
    return $parts[0];
}

sub _auth_for_registry {
    my ($self, $registry, $config) = @_;

    my $auths = $config->{auths} // {};

    my @candidates = ($registry);
    if ($registry eq 'https://index.docker.io/v1/'
        || $registry eq 'index.docker.io'
        || $registry eq 'docker.io') {
        push @candidates,
            'https://index.docker.io/v1/',
            'https://index.docker.io/v2/',
            'index.docker.io',
            'docker.io';
    }

    my $entry;
    for my $key (@candidates) {
        if (exists $auths->{$key}) {
            $entry = $auths->{$key};
            last;
        }
    }
    return undef unless $entry;

    my %auth = (serveraddress => $registry);

    if ($entry->{identitytoken}) {
        $auth{identitytoken} = $entry->{identitytoken};
        return \%auth;
    }

    if ($entry->{auth}) {
        my $decoded = eval { decode_base64($entry->{auth}) };
        if (defined $decoded && $decoded =~ /^([^:]+):(.*)$/s) {
            $auth{username} = $1;
            $auth{password} = $2;
            return \%auth;
        }
    }

    if (defined $entry->{username} || defined $entry->{password}) {
        $auth{username} = $entry->{username} if defined $entry->{username};
        $auth{password} = $entry->{password} if defined $entry->{password};
        return \%auth;
    }

    return undef;
}

sub tag_image {
    my ($self, %arg) = @_;

    my $source = $arg{source};
    my $target = $arg{target};

    my ( $repo, $tag ) = $self->_split_image_ref($target);

    $self->docker->images->tag(
        $source,
        repo => $repo,
        defined $tag ? ( tag => $tag ) : (),
    );
}

sub push_image {
    my ($self, %arg) = @_;

    my $image_ref = $arg{image_ref};
    my $auth = exists $arg{auth} ? $arg{auth} : $self->auth_for_image_ref($image_ref);

    my $events;
    eval {
        $events = $self->docker->images->push($image_ref, auth => $auth);
    };

    if (my $err = $@) {
        # API::Docker 0.004 croaks on a push failure instead of handing back the
        # errorDetail event in the returned array (against Docker an
        # API::Docker::Error::Stream with ->events, on Podman it may be a plain
        # HTTP error). Pull the message off the stream event when it is there,
        # otherwise report the exception itself (api-docker #12).
        my $message = "$err";
        if (ref $err && $err->can('events')) {
            for my $event (@{ $err->events }) {
                next unless $event->{errorDetail};
                $message = $event->{errorDetail}{message};
                last;
            }
        }
        $self->logger_fatal->("Push error: " . $message);
    }

    # A success still returns the raw array; keep scanning it, defensively, in
    # case an engine reports a failure inside a 200 stream.
    for my $event (@{$events // []}) {
        if ($event->{errorDetail}) {
            $self->logger_fatal->("Push error: " . $event->{errorDetail}{message});
        }
    }
}

sub inspect_image {
    my ($self, $image_ref) = @_;

    return $self->docker->images->inspect($image_ref);
}

# Ask the *registry* whether a reference is already published, through the
# engine's GET /distribution/{name}/json. Credentials are optional: without
# any, the lookup is anonymous, which is what a public image needs.
#
# API::Docker's exists() croaks instead of answering "no" when the engine has
# no /distribution route -- rootless Podman has none, measured -- and that
# croak is deliberately not caught here. "This engine cannot answer" is not
# the same as "the tag is free", and only the caller can decide what to do
# about the difference.
sub remote_tag_exists {
    my ($self, $image_ref) = @_;

    my $auth = $self->auth_for_image_ref($image_ref);

    return $self->docker->distribution->exists(
        $image_ref,
        defined $auth ? ( auth => $auth ) : (),
    ) ? 1 : 0;
}

# Pre-flight for the release push: hand the engine, through POST /auth, the
# very credentials push_image would use for this reference and let the
# registry judge them. A rejected credential croaks; the caller is meant to
# make that fatal before anything is built.
#
# Returns undef when no credential could be resolved for the reference. That
# is not a failure -- an anonymous push to a public registry is a legal thing
# to do, and system->auth croaks on an empty AuthConfig, so there would be
# nothing to ask about.
sub verify_auth_for_image_ref {
    my ($self, $image_ref) = @_;

    my $auth = $self->auth_for_image_ref($image_ref);
    return undef unless $auth;

    return $self->docker->system->auth(auth => $auth);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Docker::API::Client - Thin adapter around API::Docker

=head1 VERSION

version 0.105

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
