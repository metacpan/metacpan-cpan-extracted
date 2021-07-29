package Lemonldap::NG::Portal::Plugins::GrantSession;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_BADCREDENTIALS
  PE_SESSIONNOTGRANTED
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant afterData => 'run';

has rules => ( is => 'rw', default => sub { {} } );

sub init {
    my ($self) = @_;
    foreach ( keys %{ $self->conf->{grantSessionRules} // {} } ) {
        $self->logger->debug("GrantRule key -> $_");
        $self->logger->debug(
            "GrantRule value -> " . $self->conf->{grantSessionRules}->{$_} );
        my $rule = $self->p->buildRule( $self->conf->{grantSessionRules}->{$_},
            'grantSessionRules' );
        next unless ($rule);
        $self->rules->{$_} = $rule;
    }
    return 1;
}

sub run {
    my ( $self, $req ) = @_;

    sub sortByComment {
        my $A = ( $a =~ /^.*?##(.*)$/ )[0];
        my $B = ( $b =~ /^.*?##(.*)$/ )[0];
        return !( $A or $B ) ? $a cmp $b : !$A ? 1 : !$B ? -1 : $A cmp $B;
    }

    # Avoid display notification if AuthResult is not null
    if ( $req->authResult > PE_OK ) {
        $self->logger->debug(
            "Bad authentication, do not check grant session rules");
        return PE_BADCREDENTIALS;
    }

    foreach ( sort sortByComment keys %{ $self->rules } ) {
        my $rule = $self->conf->{grantSessionRules}->{$_};
        $self->logger->debug("Grant session condition -> $rule");
        unless ( $self->rules->{$_}->( $req, $req->sessionInfo ) ) {
            $req->userData( {} );

            # Catch rule message
            $_ =~ /^(.*?)##.*$/;
            if ($1) {
                $self->logger->debug("Message -> $1");

                # Message can contain session data as user attributes or macros
                my $hd  = $self->p->HANDLER;
                my $msg = $hd->substitute($1);
                unless ( $msg = $hd->buildSub($msg) ) {
                    my $error = $hd->tsv->{jail}->error || '???';
                    $self->error("Bad message -> $error");
                    return PE_OK;
                }
                $msg = $msg->( $req, $req->sessionInfo );
                $self->logger->debug("Transformed message -> $msg");
                $req->info(
                    $self->loadTemplate(
                        $req, 'simpleInfo', params => { trspan => $msg }
                    )
                );
                $self->userLogger->error( 'User "'
                      . $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
                      . '" was not granted to open session (rule ->'
                      . "$rule)" );
                $req->urldc( $self->conf->{portal} );
                return $req->authResult(PE_SESSIONNOTGRANTED);
            }
            else {
                $self->userLogger->error( 'User "'
                      . $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
                      . '" was not granted to open session (rule -> '
                      . $self->conf->{grantSessionRules}->{$_}
                      . ")" );
                $req->urldc( $self->conf->{portal} );
                return $req->authResult(PE_SESSIONNOTGRANTED);
            }
        }
    }

    # Log
    my $user = $req->{sessionInfo}->{ $self->conf->{whatToTrace} };
    my $mod  = $req->{sessionInfo}->{_auth};
    $self->userLogger->notice(
        "Session granted for $user by $mod ($req->{sessionInfo}->{ipAddr})")
      if $user;
    return PE_OK;
}

1;
