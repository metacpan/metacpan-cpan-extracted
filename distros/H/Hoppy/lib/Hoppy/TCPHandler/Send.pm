package Hoppy::TCPHandler::Send;
use strict;
use warnings;
use base qw( Hoppy::Base );

sub do_handle {
    my $self    = shift;
    my $poe     = shift;
    my $message = shift;
    $message ||= $poe->args->[0];
    my $heap = $poe->heap;
    if ( $heap->{client} ) {
        $heap->{client}->put($message);
    }
}

1;
__END__

=head1 NAME

Hoppy::TCPHandler::Send - TCP handler class that will be used when Hoppy should send data to client. 

=head1 SYNOPSIS

=head1 DESCRIPTION

TCP handler class that will be used when Hoppy should send data to client. 

=head1 METHODS

=head2 do_handle($poe)

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut