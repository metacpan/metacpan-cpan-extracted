package Lemonldap::NG::Portal::Plugins::AdaptativeAuthenticationLevel;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
);

our $VERSION = '2.0.10';

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant aroundSub => { 'store' => 'adaptAuthenticationLevel' };

has rules => ( is => 'rw', default => sub { {} } );

sub init {
    my ($self) = @_;
    $self->logger->debug('Init AdaptativeAuthenticationLevel plugin');

    foreach (
        keys %{ $self->conf->{adaptativeAuthenticationLevelRules} // {} } )
    {
        $self->logger->debug("adaptativeAuthenticationLevelRules key -> $_");
        $self->logger->debug( "adaptativeAuthenticationLevelRules value -> "
              . $self->conf->{adaptativeAuthenticationLevelRules}->{$_} );

        my $rule =
          $self->p->buildRule( $_, 'adaptativeAuthenticationLevelRules' );
        next unless $rule;
        $self->rules->{$_} = $rule;
    }

    return 1;
}

sub adaptAuthenticationLevel {
    my ( $self, $sub, $req ) = @_;

    my $userid = $req->sessionInfo->{ $self->conf->{whatToTrace} };
    $self->logger->debug("Check adaptative authentication rules for $userid");

    my $authenticationLevel = $req->sessionInfo->{authenticationLevel};
    $self->logger->debug(
        "Current authentication level for $userid is $authenticationLevel");

    my $updatedAuthenticationLevel = $authenticationLevel;

    foreach ( keys %{ $self->rules } ) {
        my $rule = $_;
        $self->logger->debug(
            "Check adaptativeAuthenticationLevelRules -> $rule");
        if ( $self->rules->{$_}->( $req, $req->sessionInfo ) ) {
            my $levelOperation =
              $self->conf->{adaptativeAuthenticationLevelRules}->{$_};
            $self->logger->debug(
"User $userid match rule, apply $levelOperation on authentication level"
            );

            my ( $op, $level ) = ( $levelOperation =~ /([=+-])?(\d+)/ );
            $updatedAuthenticationLevel = $level if ( !$op or $op eq '=' );
            $updatedAuthenticationLevel += $level if ( $op and $op eq '+' );
            $updatedAuthenticationLevel -= $level if ( $op and $op eq '-' );
            $self->logger->debug(
"Authentication level for $userid is now $updatedAuthenticationLevel"
            );
        }
    }

    if ( $authenticationLevel ne $updatedAuthenticationLevel ) {
        $self->logger->debug("Authentication level has changed for $userid");
        $req->sessionInfo->{authenticationLevel} = $updatedAuthenticationLevel;
    }

    return $sub->($req);
}

1;
