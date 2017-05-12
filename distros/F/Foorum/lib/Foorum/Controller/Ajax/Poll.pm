package Foorum::Controller::Ajax::Poll;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';

sub vote : Local {
    my ( $self, $c ) = @_;

    return $c->res->body('LOGIN FIRST') unless ( $c->user_exists );

    my $poll_id   = $c->req->param('poll_id');
    my @option_id = $c->req->param('option_id');
    return $c->res->body('PLEASE SELECT ONE') unless ( scalar @option_id );

    # check the 'multi', 'duration' and 'anonymous'
    my $poll = $c->model('DBIC::Poll')->find( { poll_id => $poll_id, },
        { columns => [ 'multi', 'duration', 'anonymous' ], } );

    return $c->res->body('NO SUCH POLL') unless ($poll);

# return $c->res->body('ANONYMOUS NOT ALLOWED') if (not $poll->anonymous and $c->user_exists);
    return $c->res->body('MULTI_VOTE DENIED')
        if ( scalar @option_id > 1 and not $poll->multi );
    return $c->res->body('VOTE EXPIRE') if ( time() > $poll->duration );
    return $c->res->body('ALREADY VOTED')
        if (
        $c->model('DBIC::PollResult')->count(
            {   poster_id => $c->user->user_id,
                poll_id   => $poll_id,
            }
        )
        );

    my $i = 0;
    foreach (@option_id) {
        next unless (/^\d+$/);
        my $has_it = $c->model('DBIC::PollOption')->search(
            {   poll_id   => $poll_id,
                option_id => $_,
            }
        )->update( { vote_no => \'vote_no + 1', } );
        $c->log->debug("has_it: $has_it");
        if ( $has_it and '0E0' ne $has_it ) {
            $c->model('DBIC::PollResult')->create(
                {   poll_id   => $poll_id,
                    option_id => $_,
                    poster_id => $c->user->user_id,
                    poster_ip => $c->req->address,
                }
            );
            $i++;
        }
    }

    $c->model('DBIC::Poll')->search( { poll_id => $poll_id, } )
        ->update( { vote_no => \"vote_no + $i", } );

    $c->res->body('OK');
}

# override Root.pm
sub end : Private {
    my ( $self, $c ) = @_;

}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
