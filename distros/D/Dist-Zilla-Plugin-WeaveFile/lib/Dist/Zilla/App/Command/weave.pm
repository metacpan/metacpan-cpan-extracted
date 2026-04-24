## no critic (NamingConventions::Capitalization)
## no critic (ControlStructures::ProhibitPostfixControls)
## no critic (InputOutput::RequireCheckedSyscalls)
## no critic (ControlStructures::ProhibitUnlessBlocks)
package Dist::Zilla::App::Command::weave;

use strict;
use warnings;
use 5.010;
use feature qw( say );

# ABSTRACT: Create files by weaving them from POD, metadata, and snippets

our $VERSION = '0.002';

use Carp qw( croak );
use Dist::Zilla::App -command;
use List::Util qw( first );
use Path::Tiny qw( path );

use Dist::Zilla::Plugin::WeaveFile::Engine;

sub abstract { return 'Create project files from weave config' }    ## no critic (NamingConventions::ProhibitAmbiguousNames)

sub usage_desc { return 'dzil weave [--list] [<file>]' }

sub opt_spec {
    return ( [ 'list' => 'list files defined by WeaveFile plugin entries' ], [ 'version|V' => 'print version' ], );
}

sub validate_args {
    my ( $self, $opt, $arg ) = @_;
    my ( undef, @extra ) = @{$arg};
    croak( 'weave accepts at most one argument (filename), ignoring: ' . join q{,}, @extra )
      if @extra;
    return;
}

sub execute {
    my ( $self, $opt, $arg ) = @_;
    my $zilla = $self->zilla;

    if ( $opt->{'version'} ) {
        say __PACKAGE__ . q{ } . $VERSION;
        return;
    }

    my @plugins = grep { $_->isa('Dist::Zilla::Plugin::WeaveFile') && $_->plugin_name ne 'WeaveFile' } @{ $zilla->plugins };

    if ( $opt->{'list'} ) {
        for my $plugin (@plugins) {
            say $plugin->file;
        }
        return;
    }

    unless (@plugins) {
        $zilla->log_fatal('No [WeaveFile / ...] plugins found in dist.ini');
    }

    $zilla->ensure_built;

    if ( @{$arg} ) {
        my ($filename) = @{$arg};
        my $plugin = first { $_->file eq $filename } @plugins;

        # croak "No [WeaveFile] plugin for file '$filename'" unless $plugin;
        $zilla->log_fatal( [ 'No [WeaveFile] plugin for file \'%s\'', $filename ] ) unless $plugin;
        $self->_generate_file($plugin);
    }
    else {
        for my $plugin (@plugins) {
            $self->_generate_file($plugin);
        }
    }

    return;
}

sub _generate_file {
    my ( $self, $plugin ) = @_;
    my $zilla = $self->zilla;

    my $engine = Dist::Zilla::Plugin::WeaveFile::Engine->new(
        config_path => $plugin->config,
        root_dir    => "${\$zilla->root}",
        dist        => $self->_dist_metadata(),
    );

    my $content = $engine->render_file( $plugin->file );
    my $target  = path( $zilla->root, $plugin->file );
    $target->parent->mkpath;
    $target->spew_utf8($content);
    $zilla->log("Generated $target");

    return;
}

sub _dist_metadata {
    my ($self) = @_;
    my $zilla = $self->zilla;
    return {
        name     => $zilla->name,
        abstract => $zilla->abstract,
        author   => $zilla->authors->[0],
        authors  => $zilla->authors,
        version  => $zilla->version,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::weave - Create files by weaving them from POD, metadata, and snippets

=head1 VERSION

version 0.002

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
