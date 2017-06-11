package HPC::Runner::Command::Utils::Plugin;

use MooseX::App::Role;
use IO::File;
use File::Path qw(make_path remove_tree);

use IPC::Cmd;
use Cwd qw(getcwd);
use Try::Tiny;
use List::MoreUtils qw(uniq);

with 'MooseX::Object::Pluggable';

=head1 HPC::Runner::Command::Utils::Plugin

Take care of all file operations

=cut

=head2 Attributes

=cut

=head3 plugins

Load plugins that are used both by the submitter and executor such as logging pluggins

=cut

option 'plugins' => (
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load aplication plugins',
    cmd_split     => qr/,/,
    required      => 0,
);

option 'plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for application plugins',
    required      => 0,
);

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
);

=head3 job_plugins

Load job execution plugins

=cut

option 'job_plugins' => (
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load job execution plugins',
    cmd_split     => qr/,/,
    required      => 0,
);

option 'job_plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for job_plugins',
    required      => 0,
);

=head2 Subroutines

=cut

=head3 gen_load_plugins

=cut

sub gen_load_plugins {
    my $self = shift;

    return unless $self->plugins;

    $self->app_load_plugins( $self->plugins );
    $self->parse_plugin_opts( $self->plugins_opts );
}

=head3 hpc_load_plugins

=cut

sub hpc_load_plugins {
    my $self = shift;

    return unless $self->hpc_plugins;

    $self->app_load_plugins( $self->hpc_plugins );
    $self->parse_plugin_opts( $self->hpc_plugins_opts );
}

=head2 Subroutines

=head3 hpc_load_plugins

=cut

sub job_load_plugins {
    my $self = shift;

    return unless $self->job_plugins;

    $self->app_load_plugins( $self->job_plugins );
    $self->parse_plugin_opts( $self->job_plugins_opts );
}

=head3 app_load_plugin

=cut

sub app_load_plugins {
    my $self    = shift;
    my $plugins = shift;

    return unless $plugins;

    foreach my $plugin ( @{$plugins} ) {
        try {
            $self->load_plugin($plugin);
        }
        catch {
            $self->app_log->warn("Could not load plugin $plugin!\n$_");
            return;
        };
        $self->app_log->info( 'Loaded plugin ' . $plugin );
    }

}

=head3 parse_plugin_opts

parse the opts from --plugin_opts

=cut

sub parse_plugin_opts {
    my $self     = shift;
    my $opt_href = shift;

    return unless $opt_href;
    while ( my ( $k, $v ) = each %{$opt_href} ) {
        $self->$k($v) if $self->can($k);
    }
}

=head3 create_plugin_str

Make sure to pass plugins to job runner

=cut

sub create_plugin_str {
    my $self = shift;

    my $plugin_str = "";

    if ( $self->job_plugins ) {
        my @uniq = uniq( @{ $self->job_plugins } );
        $self->job_plugins( \@uniq );
        $plugin_str .= " \\\n\t";
        $plugin_str .= "--job_plugins " . join( ",", @{ $self->job_plugins } );
        $plugin_str .= " \\\n\t" if $self->job_plugins_opts;
        $plugin_str .=
          $self->unparse_plugin_opts( $self->job_plugins_opts, 'job_plugins' )
          if $self->job_plugins_opts;
    }

    if ( $self->plugins ) {
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
