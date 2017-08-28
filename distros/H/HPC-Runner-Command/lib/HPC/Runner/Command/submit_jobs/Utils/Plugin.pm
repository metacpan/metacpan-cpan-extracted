package HPC::Runner::Command::submit_jobs::Utils::Plugin;

use MooseX::App::Role;
use namespace::autoclean;
use List::MoreUtils qw(first_index indexes uniq);

with 'MooseX::Object::Pluggable';

=head3 hpc_plugins

Load hpc_plugins. PBS, Slurm, Web, etc.

=cut

option 'hpc_plugins' => (
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load hpc_plugins',
    cmd_split     => qr/,/,
    required      => 0,
    default       => sub { return ['Slurm'] },
);

option 'hpc_plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for hpc_plugins',
    required      => 0,
    default       => sub { {} },
);

=head3 hpc_load_plugins

=cut

sub hpc_load_plugins {
    my $self = shift;

    return unless $self->hpc_plugins;

    $self->app_load_plugins( $self->hpc_plugins );
    $self->parse_plugin_opts( $self->hpc_plugins_opts );
}

after 'hpc_load_plugins' => sub {
    my $self = shift;

    if ( $self->has_config_files ) {
        $self->load_configs;
    }
};

=head3 create_plugin_str

Make sure to pass plugins to job runner

=cut

sub create_plugin_str {
    my $self = shift;

    my $plugin_str = "";

    ##TODO Update this if we don't have plugin strings
    if ( $self->has_job_plugins ) {
        my @uniq = uniq( @{ $self->job_plugins } );
        $self->job_plugins( \@uniq );
        $plugin_str .= " \\\n\t";
        $plugin_str .= "--job_plugins " . join( ",", @{ $self->job_plugins } );

        $plugin_str .= " \\\n\t" if $self->job_plugins_opts;
        $plugin_str .=
          $self->unparse_plugin_opts( $self->job_plugins_opts, 'job_plugins' )
          if $self->job_plugins_opts;
    }

    if ( $self->has_plugins ) {
        my @uniq = uniq( @{ $self->job_plugins } );
        $self->job_plugins( \@uniq );
        $plugin_str .= " \\\n\t";
        $plugin_str .= "--plugins " . join( ",", @{ $self->plugins } );
        $plugin_str .= " \\\n\t" if $self->plugins_opts;
        $plugin_str .=
          $self->unparse_plugin_opts( $self->plugins_opts, 'plugins' )
          if $self->plugins_opts;
    }

    return $plugin_str;
}

sub unparse_plugin_opts {
    my $self     = shift;
    my $opt_href = shift;
    my $opt_opt  = shift;

    my $opt_str = "";

    return unless $opt_href;

    #Get the opts

    while ( my ( $k, $v ) = each %{$opt_href} ) {
        next unless $k;
        $v = "" unless $v;
        $opt_str .= "--$opt_opt" . "_opts " . $k . "=" . $v . " ";
    }

    return $opt_str;
}

1;
