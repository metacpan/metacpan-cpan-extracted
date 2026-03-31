package Developer::Dashboard::PluginManager;
$Developer::Dashboard::PluginManager::VERSION = '0.72';
use strict;
use warnings;

use File::Spec;

use Developer::Dashboard::JSON qw(json_decode);

# new(%args)
# Constructs the plugin definition loader.
# Input: paths object.
# Output: Developer::Dashboard::PluginManager object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    return bless { paths => $paths }, $class;
}

# plugin_files()
# Lists plugin definition files from configured plugin roots.
# Input: none.
# Output: sorted list of plugin file paths.
sub plugin_files {
    my ($self) = @_;
    my @roots = grep { defined && -d } (
        $self->{paths}->plugins_root,
        $self->{paths}->repo_plugins_root,
    );

    my @files;
    my %seen;
    for my $root (@roots) {
        opendir my $dh, $root or next;
        while ( my $entry = readdir $dh ) {
            next if $entry eq '.' || $entry eq '..';
            next if $entry !~ /\.json$/;
            my $file = File::Spec->catfile( $root, $entry );
            next if $seen{$file}++;
            push @files, $file;
        }
        closedir $dh;
    }

    return sort @files;
}

# plugins()
# Loads and decodes all valid plugin definition files.
# Input: none.
# Output: list of plugin hash references.
sub plugins {
    my ($self) = @_;
    my @plugins;
    for my $file ( $self->plugin_files ) {
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        my $data = json_decode(<$fh>);
        if ( ref($data) eq 'ARRAY' ) {
            push @plugins, grep { ref($_) eq 'HASH' } @$data;
            next;
        }
        push @plugins, $data if ref($data) eq 'HASH';
    }
    return @plugins;
}

# path_aliases()
# Merges plugin-provided path aliases.
# Input: none.
# Output: hash reference of alias-to-path mappings.
sub path_aliases {
    my ($self) = @_;
    my %aliases;
    for my $plugin ( $self->plugins ) {
        next if ref( $plugin->{path_aliases} ) ne 'HASH';
        @aliases{ keys %{ $plugin->{path_aliases} } } = values %{ $plugin->{path_aliases} };
    }
    return \%aliases;
}

# collectors()
# Returns collector definitions contributed by plugins.
# Input: none.
# Output: array reference of collector job hashes.
sub collectors {
    my ($self) = @_;
    my @collectors;
    for my $plugin ( $self->plugins ) {
        push @collectors, @{ $plugin->{collectors} || [] } if ref( $plugin->{collectors} ) eq 'ARRAY';
    }
    return \@collectors;
}

# providers()
# Returns provider page definitions contributed by plugins.
# Input: none.
# Output: array reference of provider hashes.
sub providers {
    my ($self) = @_;
    my @providers;
    for my $plugin ( $self->plugins ) {
        push @providers, @{ $plugin->{providers} || [] } if ref( $plugin->{providers} ) eq 'ARRAY';
    }
    return \@providers;
}

# docker_config()
# Merges docker compose configuration contributed by plugins.
# Input: none.
# Output: docker configuration hash reference.
sub docker_config {
    my ($self) = @_;
    my %docker = (
        addons => {},
        env    => {},
        modes  => {},
    );

    for my $plugin ( $self->plugins ) {
        next if ref( $plugin->{docker} ) ne 'HASH';
        my $cfg = $plugin->{docker};
        push @{ $docker{files} }, @{ $cfg->{files} || [] } if ref( $cfg->{files} ) eq 'ARRAY';
        push @{ $docker{services} }, @{ $cfg->{services} || [] } if ref( $cfg->{services} ) eq 'ARRAY';
        if ( ref( $cfg->{addons} ) eq 'HASH' ) {
            @{$docker{addons}}{ keys %{ $cfg->{addons} } } = values %{ $cfg->{addons} };
        }
        if ( ref( $cfg->{modes} ) eq 'HASH' ) {
            @{$docker{modes}}{ keys %{ $cfg->{modes} } } = values %{ $cfg->{modes} };
        }
        if ( ref( $cfg->{env} ) eq 'HASH' ) {
            @{$docker{env}}{ keys %{ $cfg->{env} } } = values %{ $cfg->{env} };
        }
    }

    return \%docker;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PluginManager - plugin definition loader

=head1 SYNOPSIS

  my $plugins = Developer::Dashboard::PluginManager->new(paths => $paths);
  my $providers = $plugins->providers;

=head1 DESCRIPTION

This module loads JSON plugin definitions and exposes their contributed runtime
extensions such as path aliases, collectors, providers, and docker config.

=head1 METHODS

=head2 new, plugin_files, plugins, path_aliases, collectors, providers, docker_config

Load and expose plugin contributions.

=cut
