use utf8;
package Interchange6::Schema::ResultSet::Session;

=head1 NAME

Interchange6::Schema::ResultSet::Session

=cut

=head1 SYNOPSIS

Check for expired sessions and carts.

=cut

use strict;
use warnings;
use mro 'c3';

use DateTime;
use Time::Duration::Parse;

use parent 'Interchange6::Schema::ResultSet';

=head2 expire( $expires )

Checks for expired sessions where I<$expires> is either in seconds or
human readable format.  Example '2 hours'.  If the cart user is
registered the session will be deleted but and the cart's session_id
will be made NULL.  Anonymous sessions/carts will be deleted.

=cut

sub expire {
    my ($self, $expires) = @_;
    my $schema = $self->result_source->schema;
    my $dtf = $schema->storage->datetime_parser;
    my $duration;

    # converting to seconds
    if (defined $expires) {
        if ($expires =~ /^\d+$/) {
            # already got seconds
            $duration = $expires;
        }
        else {
            $duration = parse_duration($expires);
        }
    }

    unless ($duration) {
        die "$0: Session expiration not set.\n";
    }

    my $max = DateTime->now->subtract( seconds => $duration );

    #find expired sessions
    my $session = $self->search(
        {
            last_modified => { '<=' => $dtf->format_datetime($max) },
        }
    );

    while (my $session_rs = $session->next) {
        # check for payment orders with this session
        my $po_rs = $session_rs->search_related('payment_orders');
        while (my $po = $po_rs->next) {
            $po->update({ sessions_id => undef });
        }
        # check for carts with this session
        my $cart_rs = $session_rs->search_related('carts');
        while (my $cart = $cart_rs->next) {
            my $user_id = $cart->users_id;
            # check for user
            if ($user_id) {
                $cart->update({ sessions_id => undef });
            } else {
                $cart->delete;
            }
        }
        $session_rs->delete;
    }
}


1;
