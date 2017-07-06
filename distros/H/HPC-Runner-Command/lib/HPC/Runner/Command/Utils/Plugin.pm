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
    traits   => ['Array'],
    is            => 'rw',
    isa           => 'ArrayRef[Str]',
    documentation => 'Load aplication plugins',
    cmd_split     => qr/,/,
    required      => 0,
    default       => sub { [] },
    handles   => {
        has_plugins   => 'count',
        join_plugins  => 'join',
    },
);

option 'plugins_opts' => (
    is            => 'rw',
    isa           => 'HashRef',
    documentation => 'Options for application plugins',
    required      => 0,
    default       => sub { {} },
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


=head2 Subroutines

=head3 after *load_plugins

After loading the plugins make sure to reload the configs - to get any options we didn't get the first time around

=cut

after 'gen_load_plugins'  => sub {
    my $self = shift;

    if ( $self->has_config_files ) {
        $self->load_configs;
    }
};

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

1;
