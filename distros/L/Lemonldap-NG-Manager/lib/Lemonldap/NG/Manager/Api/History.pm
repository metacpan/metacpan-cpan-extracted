# Miscenalleous endpoints
package Lemonldap::NG::Manager::Api::History;

our $VERSION = '2.17.0';

package Lemonldap::NG::Manager::Api;
use Lemonldap::NG::Common::Session;

use strict;
use Mouse;
extends 'Lemonldap::NG::Manager::Api::Common';

sub getHistory {
    my ( $self, $req, $subpath ) = @_;

    my $uid = $req->param('uid');
    return $self->sendError( $req, "Missing user identifier", 404 )
      unless ($uid);

    my ( $success, $failed );
    my $result = $req->param('result') || "any";
    if ( $result eq "any" ) {
        $success = 1;
        $failed  = 1;
    }
    elsif ( $result eq "success" ) {
        $success = 1;
    }
    elsif ( $result eq "failed" ) {
        $failed = 1;
    }
    else {
        return $self->sendError( $req, "Unknown result value $result", 400 );
    }

    if ( !$subpath ) {
        my $result = $self->getHistoryForUser( $uid, $success, $failed );
        if ($result) {
            return $self->sendJSONresponse( $req, $result );
        }
        else {
            return $self->sendError( $req, "No such user", 404 );
        }
    }
    elsif ( $subpath eq "last" ) {
        my $result = $self->getLastForUser( $uid, $success, $failed );
        if ($result) {
            return $self->sendJSONresponse( $req, $result );
        }
        else {
            return $self->sendError( $req, "No such event", 404 );
        }
    }
    else {
        return $self->sendError( $req, "Unknown path $subpath", 404 );
    }
    return $self->sendError( $req, "Unexpected error", 500 );
}

sub getLastForUser {
    my ( $self, $uid, $success, $failed ) = @_;
    my $history = $self->getHistoryForUser( $uid, $success, $failed ) || [];
    if (@$history) {
        return $history->[0];
    }
    else {
        return;
    }
}

sub getHistoryForUser {
    my ( $self, $uid, $success, $failed ) = @_;

    my $sessions = $self->_getPSessions($uid);
    if ( $sessions and ref($sessions) eq "HASH" ) {
        for my $id ( keys %$sessions ) {
            my $session = $sessions->{$id};
            next unless $session->{'_session_kind'} eq "Persistent";
            my @all;
            if ( $session->{_loginHistory} ) {
                my $successHistory = [];
                my $failedHistory  = [];
                if ( $success and $session->{_loginHistory}->{successLogin} ) {
                    $successHistory = $session->{_loginHistory}->{successLogin};
                }
                if ( $failed and $session->{_loginHistory}->{failedLogin} ) {
                    $failedHistory = $session->{_loginHistory}->{failedLogin};
                }
                $_->{result} = "success" for (@$successHistory);
                $_->{result} = "failed"  for (@$failedHistory);
                @all =
                  sort { ( $b->{_utime} || 0 ) <=> ( $a->{_utime} || 0 ) }
                  @$successHistory, @$failedHistory;
                $_->{date} = delete $_->{_utime} for (@all);
            }
            return [@all];
        }
        return undef;
    }
    else {
        return undef;
    }
}

sub _getPSessions {
    my ( $self, $uid ) = @_;
    my $mod = $self->_getPersistentMod;
    $self->logger->debug("Looking for persistent session for $uid ...");

    my $sessions =
      Lemonldap::NG::Common::Apache::Session->searchOn( $mod->{options},
        '_session_uid', $uid,
        ( '_session_kind', '_session_uid', '_session_id', '_loginHistory' ) );

    $self->logger->debug(
        defined $sessions
        ? "Session for $uid found."
        : " No session found for $uid"
    );
    return $sessions;
}

1;
