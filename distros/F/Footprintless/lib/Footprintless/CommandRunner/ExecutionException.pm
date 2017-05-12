use strict;
use warnings;

package Footprintless::CommandRunner::ExecutionException;
$Footprintless::CommandRunner::ExecutionException::VERSION = '1.24';
# ABSTRACT: An exception for failures when executing commands
# PODNAME: Footprintless::CommandRunner::ExecutionException

use Term::ANSIColor;
use overload '""' => 'to_string';

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _init {
    my ( $self, $command, $exit_code, $message, $stderr ) = @_;

    $self->{command}   = $command;
    $self->{exit_code} = $exit_code;
    $self->{message}   = $message;
    $self->{stderr}    = $stderr;
    $self->{trace}     = [];

    return $self;
}

sub exit {
    my ( $self, $verbose ) = @_;
    print( STDERR "$self->{message}\n" ) if ( $self->{message} );
    print( STDERR "$self->{stderr}\n" )  if ( $self->{stderr} );
    if ($verbose) {
        print( STDERR colored( ['red'], "[$self->{command}]" ),
            " failed ($self->{exit_code})\n" );
        print( STDERR $self->_trace_string(), "\n" );
    }
    exit $self->{exit_code};
}

sub get_command {
    return $_[0]->{command};
}

sub get_exit_code {
    return $_[0]->{exit_code};
}

sub get_message {
    return $_[0]->{message};
}

sub get_stderr {
    return $_[0]->{stderr};
}

sub get_trace {
    return $_[0]->{trace};
}

sub PROPAGATE {
    my ( $self, $file, $line ) = @_;
    push( @{ $self->{trace} }, [ $file, $line ] );
}

sub to_string {
    my ($self) = @_;

    my @parts = ( $self->{exit_code} );
    push( @parts, ": $self->{message}" ) if ( $self->{message} );
    push( @parts, "\n****STDERR****\n$self->{stderr}\n****STDERR****" )
        if ( $self->{stderr} );
    push( @parts, "\n", $self->_trace_string() );

    return join( '', @parts );
}

sub _trace_string {
    my ($self) = @_;
    my @parts = ();
    if ( @{ $self->{trace} } ) {
        push( @parts, "****TRACE****" );
        foreach my $stop ( @{ $self->{trace} } ) {
            push( @parts, "$stop->[0]($stop->[1])" );
        }
        push( @parts, "\n****TRACE****" );
    }
    return join( '', @parts );
}

1;

__END__

=pod

=head1 NAME

Footprintless::CommandRunner::ExecutionException - An exception for failures when executing commands

=head1 VERSION

version 1.24

=head1 DESCRIPTION

An exception used by C<Footprintless::CommandRunner> to propagate 
information related to the reason a command execution failed.

=head1 CONSTRUCTORS

=head2 new($command, $exit_code, $message, $stderr)

Creates a new C<Footprintless::CommandRunner::ExecutionException> 
with the supplied information.

=head1 ATTRIBUTES

=head2 get_command()

Returns the command.

=head2 get_exit_code()

Returns the exit code.

=head2 get_message()

Returns the message.

=head2 get_stderr()

Returns the stderr.

=head2 get_trace()

Returns the stack trace when the command runner C<die>d.

=head1 METHODS

=head2 exit()

Prints diagnostic information to C<STDERR> then exits with exit code.

=head2 to_string()

Returns a string representation of this exception.

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

L<Footprintless::CommandRunner|Footprintless::CommandRunner>

=item *

L<Footprintless|Footprintless>

=back

=for Pod::Coverage PROPAGATE

=cut
