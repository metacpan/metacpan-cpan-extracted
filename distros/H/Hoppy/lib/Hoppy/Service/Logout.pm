package Hoppy::Service::Logout;
use strict;
use warnings;
use base qw( Hoppy::Service::Base );

sub work {
    my $self = shift;
    my $args = shift;

    my $user_id    = $args->{user_id};
    my $in_data    = $args->{in_data};
    my $poe        = $args->{poe};
    my $session_id = $poe->session->ID;
    my $c          = $self->context;

    my $result = $c->room->logout( $args, $poe );
    my $out_data;
    if ($result) {
        $out_data = { result => $result, error => "" };
    }
    else {
        my $message = "logout failed";
        $out_data = { result => "", error => $message };
    }
    if ( $in_data->{id} ) {
        $out_data->{id} = $in_data->{id};
    }
    my $serialized = $c->formatter->serialize($out_data);
    $c->unicast(
        {
            session_id => $session_id,
            user_id    => $args->{user_id},
            message    => $serialized
        }
    );
    if ( my $hook = $c->hook->{logout} ) {
        $hook->work($args);
    }
}

1;
__END__

=head1 NAME

Hoppy::Service::Logout - Default logout service.

=head1 SYNOPSIS

=head1 DESCRIPTION

Default logout service.

=head1 METHODS

=head2 work

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut