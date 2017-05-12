package Hoppy::TCPHandler::Connected;
use strict;
use warnings;
use base qw( Hoppy::Base );

sub do_handle {
    my $self       = shift;
    my $poe        = shift;
    my $c          = $self->context;
    my $session_id = $poe->session->ID;

    $c->{sessions}->{$session_id}       = 1;
    $c->{not_authorized}->{$session_id} = 1;

    if ( my $hook = $c->hook->{client_connect} ) {
        $hook->work( { poe => $poe } );
    }
}

1;
__END__

=head1 NAME

Hoppy::TCPHandler::Connected - TCP handler class that will be used when client connected. 

=head1 SYNOPSIS

=head1 DESCRIPTION

TCP handler class that will be used when client connected. 

=head1 METHODS

=head2 do_handle($poe)

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut