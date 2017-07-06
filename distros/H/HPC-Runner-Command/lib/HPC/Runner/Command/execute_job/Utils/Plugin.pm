package HPC::Runner::Command::execute_job::Utils::Plugin;

use MooseX::App::Role;
use namespace::autoclean;

with 'MooseX::Object::Pluggable';

=head3 job_plugins

Load job execution plugins

=cut

option 'job_plugins' => (
    traits   => ['Array'],
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load job execution plugins',
    cmd_split     => qr/,/,
    required      => 0,
    default       => sub { [] },
    handles   => {
        has_job_plugins   => 'count',
        join_job_plugins  => 'join',
    },
);

option 'job_plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for job_plugins',
    required      => 0,
    default       => sub { {} },
);

=head2 Subroutines

=head3 job_load_plugins

=cut

sub job_load_plugins {
    my $self = shift;

    return unless $self->job_plugins;

    $self->app_load_plugins( $self->job_plugins );
    $self->parse_plugin_opts( $self->job_plugins_opts );
}

=head3 after *load_plugins

After loading the plugins make sure to reload the configs - to get any options we didn't get the first time around

=cut

after 'job_load_plugins' => sub {
    my $self = shift;

    if ( $self->has_config_files ) {
        $self->load_configs;
    }
};

1;
