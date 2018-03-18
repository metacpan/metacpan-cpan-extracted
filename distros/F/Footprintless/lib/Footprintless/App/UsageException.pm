use strict;
use warnings;

package Footprintless::App::UsageException;
$Footprintless::App::UsageException::VERSION = '1.28';
# ABSTRACT: An exception that indicates the invalid usage of a command
# PODNAME: Footprintless::App::UsageException

use Term::ANSIColor;
use overload '""' => 'to_string';

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _init {
    my ( $self, $message, $coordinate ) = @_;

    $self->{message} = $message;
    $self->{trace}   = [];

    return $self;
}

sub get_message {
    return $_[0]->{message};
}

sub get_trace {
    return $_[0]->{trace};
}

sub PROPAGATE {
    my ( $self, $file, $line ) = @_;
    push( @{ $self->{trace} }, [ $file, $line ] );
}

sub to_string {
    my ( $self, $trace ) = @_;

    my @parts = ( $self->{message} );
    if ( $trace && @{ $self->{trace} } ) {
        push( @parts, "\n****TRACE****" );
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

Footprintless::App::UsageException - An exception that indicates the invalid usage of a command

=head1 VERSION

version 1.28

=head1 DESCRIPTION

An exception that indicates the invalid usage of a command

=head1 CONSTRUCTORS

=head2 new($message)

Creates a new C<Footprintless::App::UsageException> with the 
supplied information.

=head1 ATTRIBUTES

=head2 get_message()

Returns the message.

=head2 get_trace()

Returns the stack trace when the command runner C<die>d.

=head1 METHODS

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

L<Footprintless|Footprintless>

=back

=for Pod::Coverage PROPAGATE

=cut
