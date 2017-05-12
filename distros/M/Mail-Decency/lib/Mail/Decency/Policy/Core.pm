package Mail::Decency::Policy::Core;

use Moose;
extends 'Mail::Decency::Core::Child';

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::Policy::Core

=head1 DESCRIPTION

Base class for all policy modules.


=head1 CLASS ATTRIBUTES

=head2 timeout : Int

Timeout for each policy module.

Default: 15

=cut

has timeout  => ( is => 'rw', isa => 'Int', default => 15 );


=head1 METHODS

=head2 session_data

Access to current session data

=cut

sub session_data {
    return shift->server->session_data;
}


=head2 add_spam_score $weight, $details, $reject_message

See L<Mail::Decency::Policy>

=cut

sub add_spam_score {
    my ( $self, @args ) = @_;
    $self->server->add_spam_score( $self, @args );
}


=head2 go_final_state $state, $messsage

See L<Mail::Decency::Policy>

=cut

sub go_final_state {
    my ( $self, @args ) = @_;
    $self->server->go_final_state( $self, @args );
}


=head2 (del|set|has)_flag

See L<Mail::Decency::Policy::SessionItem>

=cut

sub set_flag {
    my ( $self, $flag ) = @_;
    return $self->session_data->set_flag( $flag );
}

sub has_flag {
    my ( $self, $flag ) = @_;
    return $self->session_data->has_flag( $flag );
}

sub del_flag {
    my ( $self, $flag ) = @_;
    return $self->session_data->del_flag( $flag );
}



=head2 init

Should be overwritte by module.

=cut

sub init {}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
