package Dist::Zilla::Plugin::Docker::API::Client;
# ABSTRACT: Thin adapter around API::Docker
our $VERSION = '0.103';
use Moo;
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

has docker_config_path => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        $ENV{DOCKER_CONFIG}
            ? Path::Tiny::path($ENV{DOCKER_CONFIG}, 'config.json')
            : Path::Tiny::path($ENV{HOME} // '', '.docker', 'config.json');
    },
);

has _docker_config => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = @_;
        my $path = $self->docker_config_path;
        return {} unless $path && -r "$path";
        my $data = eval { decode_json(Path::Tiny::path($path)->slurp_utf8) };
        if ($@ || !$data) {
            $self->logger->("Warning: cannot parse $path: $@") if $@;
            return {};
        }
        return $data;
    },
);

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
    my $push = $arg{push} // 0;
    my $target = $arg{target};
    my $network_mode = $arg{network_mode};
    my $platform = $arg{platform};

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

    my $progress_cb = sub {
        my ($event) = @_;
        if ($event->{errorDetail}) {
            $self->logger_fatal->("Docker build error: " . $event->{errorDetail}{message});
        }
        elsif ($event->{stream}) {
            $self->logger->($event->{stream});
        }
        elsif ($event->{progress}) {
            $self->logger->($event->{status} . ' ' . $event->{progress});
        }
        if ($event->{aux} && $event->{aux}{ID}) {
            $image_id = $event->{aux}{ID};
        }
    };

    my $tarball;
    if (ref($context) eq 'HASH') {
        if ($context->{type} eq 'dir') {
            $tarball = $self->_create_tar($context->{path}, $context->{dockerfile});
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

    if ($@) {
        $self->logger_fatal->("Docker build failed: $@");
    }

    for my $tag (@tags) {
        next if $tag eq ($tags[0] // '');
        eval {
            $docker->images->tag($image_id, repo => $tag);
        };
        if ($@) {
            $self->logger->("Warning: failed to tag image as $tag: $@");
        }
        push @processed_tags, $tag;
    }

    my $result = Dist::Zilla::Plugin::Docker::API::Result->new(
        image_id => $image_id,
        tags     => \@processed_tags,
        pushed   => [],
    );

    if ($push && @tags) {
        $self->_push_tags($docker, \@tags, \$result);
    }

    return $result;
}

sub _create_tar {
    my ($self, $dir, $dockerfile) = @_;

    eval { require Archive::Tar; };
    if ($@) {
        $self->logger_fatal->("Archive::Tar required for creating tar context: $@");
    }

    my $root = Path::Tiny::path($dir);
    my @entries = $self->_collect_files($root, $root);
    my @files;

    for my $entry (@entries) {
        my $name = $entry->relative($root)->stringify;
        next if $name =~ /^\./;
        push @files, $name => $entry->slurp_raw;
    }

    my $tar = Archive::Tar->new;
    for (my $i = 0; $i < @files; $i += 2) {
        $tar->add_data($files[$i], $files[$i+1]);
    }

    my $tarball;
    open my $fh, '>', \$tarball;
    $tar->write($fh, 1);
    close $fh;

    return \$tarball;
}

sub _collect_files {
    my ($self, $root, $dir) = @_;

    my @files;
    for my $entry ($dir->children) {
        if ($entry->is_dir) {
            push @files, $self->_collect_files($root, $entry);
        }
        else {
            push @files, $entry;
        }
    }
    return @files;
}

sub _push_tags {
    my ($self, $docker, $tags, $result_ref) = @_;

    for my $tag (@$tags) {
        $self->logger->("Pushing $tag...");

        my $push_progress = sub {
            my ($event) = @_;
            if ($event->{errorDetail}) {
                $self->logger_fatal->("Push error for $tag: " . $event->{errorDetail}{message});
            }
            elsif ($event->{progress}) {
                $self->logger->($event->{status} . ' ' . $event->{progress});
            }
        };

        my $auth = $self->auth_for_image_ref($tag);

        eval {
            my $events = $docker->images->push($tag, auth => $auth);
            for my $event (@{$events // []}) {
                $push_progress->($event);
                if ($event->{aux} && $event->{aux}{Digest}) {
                    $$result_ref->{digest} = $event->{aux}{Digest};
                }
            }
        };

        if ($@) {
            $self->logger->("Warning: failed to push $tag: $@");
        }
        else {
            push @{ $$result_ref->{pushed} }, $tag;
        }
    }
}

sub auth_for_image_ref {
    my ($self, $image_ref) = @_;
    my $registry = $self->_registry_for_image_ref($image_ref);
    return $self->_auth_for_registry($registry);
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
    my ($self, $registry) = @_;

    my $config = $self->_docker_config;
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

    $self->docker->images->tag(
        $source,
        repo => $target,
    );
}

sub push_image {
    my ($self, %arg) = @_;

    my $image_ref = $arg{image_ref};
    my $auth = exists $arg{auth} ? $arg{auth} : $self->auth_for_image_ref($image_ref);

    my $events = $self->docker->images->push($image_ref, auth => $auth);
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

sub remote_tag_exists {
    my ($self, $image_ref) = @_;

    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Docker::API::Client - Thin adapter around API::Docker

=head1 VERSION

version 0.103

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
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
