package Hoppy::Service::Login;
use strict;
use warnings;
use Data::GUID;
use base qw( Hoppy::Service::Base );

sub work {
    my $self       = shift;
    my $args       = shift;
    my $in_data    = $args->{in_data};
    my $poe        = $args->{poe};
    my $session_id = $poe->session->ID;
    ## It can generate and distribute ID automatically
    if ( $in_data->{params}->{auto} ) {
        $args->{user_id} = Data::GUID->new->as_string;
    }
    else {
        $args->{user_id} = $in_data->{params}->{user_id};
    }
    ## login
    my $c      = $self->context;
    my $result = $c->room->login(
        {
            user_id    => $args->{user_id},
            password   => $in_data->{params}->{password},
            room_id    => $in_data->{params}->{room_id},
            session_id => $session_id,
        },
        $poe
    );
    ## response
    if ( $in_data->{id} ) {
        ## set out_data
        my $out_data = {};
        if ($result) {
            $out_data = {
                result => {
                    login_id   => $args->{user_id},
                    login_time => time()
                },
                error => ""
            };
        }
        else {
            $out_data = { result => "", error => "login failed" };
        }
        $out_data->{id} = $in_data->{id};
        ## respond it
        my $serialized = $c->formatter->serialize($out_data);
        $c->unicast(
            {
                session_id => $session_id,
                user_id    => $args->{user_id},
                message    => $serialized
            }
        );
    }
    if ( my $hook = $c->hook->{login} ) {
        $hook->work($args);
    }
}
1;
__END__

=head1 NAME

Hoppy::Service::Login - Default login service.

=head1 SYNOPSIS

=head1 DESCRIPTION

Default login service.

=head1 METHODS

=head2 work

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut