package Lemonldap::NG::Portal::Plugins::PublicNotifications;

use strict;
use JSON;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
);

our $VERSION = '2.21.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant beforeAuth => 'getPublicNotifs';

has notifObject => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]
          ->p->loadedModules->{'Lemonldap::NG::Portal::Plugins::Notifications'};
    }
);

sub init {
    my ($self) = @_;
    unless ( defined $self->notifObject ) {
        $self->logger->error("Notifications must be enabled");
        return 0;
    }
    if ( $self->conf->{oldNotifFormat} ) {
        $self->logger->error("Public notifications don't support XML format");
        return 0;
    }
    return 1;
}

sub getPublicNotifs {
    my ( $self, $req ) = @_;

    # No need to query public notifs on password post
    return PE_OK if $req->method =~ /^post$/i;

    # Here we reuse existing notification getter object:
    #  - $self->notifObject : Plugins::Notifications object
    #  - $self->notifObject->module : librarie depending on chosen format
    #    (Notifications::JSON or Notifications::XML)
    #  - $self->notifObject->module->notifObject : Common::Notification
    #    storage layer
    my $errors =
      $self->notifObject->module->notifObject->getNotifications("public-error");
    my $warns =
      $self->notifObject->module->notifObject->getNotifications("public-warn");
    my $infos =
      $self->notifObject->module->notifObject->getNotifications("public-info");
    my $res = to_json( {
            "public_errors" =>
              [ map { from_json( $errors->{$_} ) } keys %$errors ],
            "public_warns" =>
              [ map { from_json( $warns->{$_} ) } keys %$warns ],
            "public_infos" => [ map { from_json( $infos->{$_} ) } keys %$infos ]

        }
    );
    $req->env->{DISPLAY_PUBLIC_NOTIFICATIONS} = 1 if $res;

    $req->data->{customScript} .= <<EOF if $res;
<script type="application/init">
{
  "publicNotifications": $res
}
</script>
<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/carousel.js?v=$self->{p}->cacheTag"></script>
EOF

    return PE_OK;
}

1;
