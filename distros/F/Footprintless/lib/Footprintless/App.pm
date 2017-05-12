use strict;
use warnings;

package Footprintless::App;
$Footprintless::App::VERSION = '1.24';
# ABSTRACT: The base application class for fpl
# PODNAME: Footprintless::App

use App::Cmd::Setup -app;
use Footprintless;
use Footprintless::Util qw(dynamic_module_new);
use Log::Any;

my $logger = Log::Any->get_logger();

# todo: remove after https://github.com/rjbs/App-Cmd/pull/60
my $pretend_self = {};

sub _configure_logging {
    my ( $self, %options ) = @_;

    my $log_configurator_module =
        $self->footprintless()->entities()->get_entity('footprintless.log_configurator');
    if ($log_configurator_module) {
        dynamic_module_new($log_configurator_module)->configure(%options);
    }
    elsif ( $options{log_level} ) {
        require Log::Any::Adapter;
        Log::Any::Adapter->set( 'Stderr',
            log_level => Log::Any::Adapter::Util::numeric_level( $options{log_level} ) );
    }
}

sub clear_pretend_self {

    #used by unit tests to clear out predend self hack between tests
    $pretend_self = {};
}

sub footprintless {
    my ($self) = @_;

    if ( !defined( $pretend_self->{footprintless} ) ) {
        $pretend_self->{footprintless} = Footprintless->new();
    }

    return $pretend_self->{footprintless};
}

sub get_command {
    my ( $self, @args ) = @_;
    my ( $command, $opt, @rest ) = $self->App::Cmd::get_command(@args);

    $self->_configure_logging(
        command   => $command,
        opt       => $opt,
        rest      => \@rest,
        log_level => delete( $opt->{log} )
    );

    return ( $command, $opt, @rest );
}

sub global_opt_spec {
    my ($self) = @_;
    return ( [ "log=s", "sets the log level", ], $self->App::Cmd::global_opt_spec() );
}

# todo: remove after https://github.com/rjbs/App-Cmd/pull/60
sub footprintless_plugin_search_paths {
    my ($self) = @_;

    my @paths = ();
    foreach my $plugin ( $self->footprintless()->plugins() ) {
        push( @paths, $plugin->command_packages() );
    }

    return @paths;
}

sub REAL_footprintless_plugin_search_paths {
    my ($self) = @_;

    unless ( $self->{plugin_search_paths} ) {
        my @paths = ();
        foreach my $plugin ( $self->footprintless()->plugins() ) {
            push( @paths, $plugin->command_packages() );
        }
        $self->{plugin_search_paths} = \@paths;
    }

    return @{ $self->{plugin_search_paths} };
}

sub plugin_search_path {
    my ($self) = @_;

    my $search_path =
        [ 'Footprintless::App::Command', $self->footprintless_plugin_search_paths() ];

    return $search_path;
}

1;

__END__

=pod

=head1 NAME

Footprintless::App - The base application class for fpl

=head1 VERSION

version 1.24

=head1 METHODS

=head2 footprintless()

Returns the instance of C<Footprintless> for this instance of the app.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<App::Cmd|App::Cmd>

=item *

L<Footprintless|Footprintless>

=back

=for Pod::Coverage clear_pretend_self get_command global_opt_spec footprintless_plugin_search_paths REAL_footprintless_plugin_search_paths plugin_search_path

=cut
