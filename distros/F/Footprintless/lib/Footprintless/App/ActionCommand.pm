use strict;
use warnings;

package Footprintless::App::ActionCommand;
$Footprintless::App::ActionCommand::VERSION = '1.24';
# ABSTRACT: A base class for action commands
# PODNAME: Footprintless::App::ActionCommand

use Carp;
use Footprintless::App -command;
use Getopt::Long::Descriptive;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _coord_desc {
    return 'COORD';
}

sub _default_action {
    return;
}

sub description {
    my ($self) = @_;

    if ( $self->{action} && !$self->{is_default_action} ) {
        return $self->{action}->description();
    }
    else {
        require Footprintless::App::DocumentationUtil;
        my $pod_description = Footprintless::App::DocumentationUtil::description($self);
        my %actions         = $self->_actions();

        my $default_action = $self->_default_action();
        $default_action =
            $default_action
            ? "\n\nDefault action: $default_action"
            : '';

        return
              $pod_description
            . "\nAvailable actions:\n\n"
            . $self->_format_actions( $self->_actions() )
            . $default_action;
    }
}

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->{action}->execute( $self->{action_opts}, $self->{action_args} );
}

sub _format_actions {
    my ( $self, %actions ) = @_;

    my %abstracts  = ();
    my $max_length = 0;
    foreach my $key ( keys(%actions) ) {
        my $length = length($key);
        $abstracts{$key} = Footprintless::App::DocumentationUtil::abstract( $actions{$key} );
        $max_length = $length if ( $length > $max_length );
    }

    return join( "\n",
        map { sprintf( "  %${max_length}s: %s", $_, $abstracts{$_} ); } sort keys(%actions) );
}

sub prepare {
    my ( $class, $app, @args ) = @_;

    my ( $opts, $remaining_args, %fields ) =
        $class->_process_args( \@args, $class->usage_desc(), $class->opt_spec() );

    my ( $coordinate, $action_name, @action_args ) = @$remaining_args;
    $fields{coordinate} = $coordinate;

    if ($action_name) {
        $fields{action_name} = $action_name;
    }
    else {
        $fields{action_name}       = $class->_default_action();
        $fields{is_default_action} = 1;
    }

    if ( $fields{action_name} ) {
        my %actions = $class->_actions();
        my $action  = $actions{ $fields{action_name} };
        if ($action) {
            { eval "require $action" };    ## no critic
            ( $fields{action}, $fields{action_opts}, $fields{action_args} ) =
                $action->prepare( $app, $app->footprintless(), $coordinate, @action_args );
        }
    }

    return (
        $class->new(
            {   app => $app,
                %fields
            }
        ),
        $opts,
        $remaining_args
    );
}

sub usage {
    my ($self) = @_;
    return ( $self->{action} && !$self->{is_default_action} )
        ? $self->{action}->usage()
        : $self->{usage};
}

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error("coordinate required") unless ( $self->{coordinate} );
    $self->usage_error("action required")     unless ( $self->{action_name} );
    $self->usage_error("invalid action [$self->{action_name}]")
        unless ( $self->{action} );

    eval { $self->{action}->validate_args( $self->{action_opts}, $self->{action_args} ); };
    if ($@) {
        $self->usage_error($@);
    }
}

1;

__END__

=pod

=head1 NAME

Footprintless::App::ActionCommand - A base class for action commands

=head1 VERSION

version 1.24

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

=back

=cut
