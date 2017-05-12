package Dist::Zilla::Plugin::CheckDeploymentHandlerFiles;

use strict;
use warnings;

our $VERSION = '0.006';

use Moose;
use namespace::autoclean;
use File::ShareDir 'module_dir';
use File::pushd;
use Class::Load 'load_class';

with 'Dist::Zilla::Role::BeforeRelease';

has schema_module => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $name = $self->zilla->name;
        $name =~ s/-/::/g;

        $name;
    }
);

has script_directory => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $mod = $self->schema_module;

        return module_dir($mod) . '/sql';
    }
);

around schema_module => sub {
    my $orig = shift;
    my $self = shift;
    my $mod = $self->$orig(@_);

    load_class($mod);

    $mod;
};

sub before_release {
    my $self = shift;
    my $version = $self->schema_module->schema_version || $self->schema_module->version;
    my $previous = $version - 1;

    # Make sure we're working in context of the build dir.
    $self->zilla->ensure_built;
    my $chdir = pushd($self->zilla->built_in);
    unshift @INC, $chdir . '/lib';

    my $script_dir = $self->script_directory . "/PostgreSQL/upgrade/$previous-$version";

    $self->log( "Checking for $script_dir" );

    if (! -e $script_dir) {
        $self->log_fatal("Did not find $script_dir - did you prepare the schema upgrade?");
    }

    return;
}

1;

=head1 NAME

Dist::Zilla::Plugin::CheckDeploymentHandlerFiles - Check you've created the DH files for this version

=head1 SYNOPSIS

    [CheckDeploymentHandlerFiles]

=head1 DESCRIPTION

If you have a schema that uses L<DBIx::Class::DeploymentHandler> then your
deployment will bail if you don't have a directory for migrating to the current
version. If your schema is part of a wider module it's fairly likely that you'll
forget to create these files because you didn't do any work on the schema.

This plugin simply bails if there's no C<x-y> directory where DH would normally
put them.

=head1 TODO

Configuration so that the user can replicate any customisation of
DeploymentHandler, thus searching for the correct directory.

=head1 BUGS

Report any issues on the github bugtracker.

=head1 AUTHOR

Alastair McGowan-Douglas <altreus@altre.us>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Alastair McGowan-Douglas.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 SEE ALSO

=over

=item L<DBIx::Class>

=item L<DBIx::Class::DeploymentHandler>

=back

