use strict;
use warnings;

package Footprintless::App::Action;
$Footprintless::App::Action::VERSION = '1.28';
# ABSTRACT: A base class for actions
# PODNAME: Footprintless::App::Action

use parent qw(App::Cmd::ArgProcessor);

use Footprintless::App -ignore;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _new {
    my ( $class, $self ) = @_;
    return bless( $self, $class );
}

sub abstract {
    my ($self_or_class) = @_;

    require Footprintless::App::DocumentationUtil;
    return Footprintless::App::DocumentationUtil::abstract($self_or_class);
}

sub description {
    my ($self_or_class) = @_;

    require Footprintless::App::DocumentationUtil;
    my $description = Footprintless::App::DocumentationUtil::description($self_or_class)
        || ucfirst( $self_or_class->abstract() );

    if ( scalar( $self_or_class->opt_spec() ) ) {
        $description .= "\n\nAvailable options:\n";
    }

    return $description;
}

sub prepare {
    my ( $class, $app, $footprintless, $coordinate, @args ) = @_;

    my ( $opts, $remaining_args, %fields ) =
        $class->_process_args( \@args, $class->usage_desc(), $class->opt_spec() );

    return (
        $class->_new(
            {   app           => $app,
                footprintless => $footprintless,
                coordinate    => $coordinate,
                %fields
            }
        ),
        $opts,
        $remaining_args
    );
}

sub opt_spec {
    return ();
}

sub usage {
    return $_[0]->{usage};
}

sub usage_error {
    my ( $self, $message, $coordinate ) = @_;
    require Footprintless::App::UsageException;
    die( Footprintless::App::UsageException->new( $message, $coordinate ) );
}

sub validate_args { }

1;

__END__

=pod

=head1 NAME

Footprintless::App::Action - A base class for actions

=head1 VERSION

version 1.28

=head1 FUNCTIONS

=head2 abstract($self_or_class) 

Returns the abstract for the action.  By default it will pull it from the
C<ABSTRACT> section of the pod.  This function should be called using
I<method invokation>.

=head2 description($self_or_class) 

Returns the description for the action.  By default it will pull it from the
C<DESCRIPTION> section of the pod.  This function should be called using
I<method invokation>.

=head2 opt_spec()

Returns an options specificatino for this action according to 
L<Getopt::Long::Descriptive>.

=head2 prepare($class, $app, $footprintless, $coordinate, @args)

Processes C<@args> to parse off the options, then generates a new instance
of the action implementation and returns the 3-tuple: action, options, 
remaining args.  See L<App::Cmd::Command::prepare> for inspiration.

=head1 METHODS

=head2 execute($opts, $args)

Executes the action.

=head2 usage()

Returns the usage object from L<Getopt::Long::Descriptive> for the action.

=head2 usage_error($message, $coordinate)

Die's with a generated message based on C<$message> and C<$coordinate>.

=head2 usage_desc() 

Returns the top level usage line.  See L<App::Cmd::Command::usage_desc> for
inspiration.

=head2 validate_args($opts, $args)

Performs additional validation on C<$opts> and C<$args>.  Calls 
L<usage_error($message, $coordinate)> if there is a problem.

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

L<Footprintless::App::DocumentationUtil|Footprintless::App::DocumentationUtil>

=back

=for Pod::Coverage _new 

=cut
