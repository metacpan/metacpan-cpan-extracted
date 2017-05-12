package Hoppy;
use strict;
use warnings;
use EV;
use POE;
use POE::Sugar::Args;
use POE::Filter::Line;
use POE::Component::Server::TCP;
use Hoppy::TCPHandler;
use UNIVERSAL::require;
use Carp;
use base qw(Hoppy::Base);

__PACKAGE__->mk_accessors($_) for qw(handler formatter service hook room);

our $VERSION = '0.01005';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->_setup;
    return $self;
}

sub start {
    my $self = shift;
    if ( my $hook = $self->hook->{start} ) {
        $hook->work();
    }
    POE::Kernel->run;
}

sub stop {
    my $self = shift;
    if ( my $hook = $self->hook->{stop} ) {
        $hook->work();
    }
    POE::Kernel->stop;
}

sub dispatch {
    my $self       = shift;
    my $in_data    = shift;
    my $poe        = shift;
    my $session_id = $poe->session->ID;
    my $method     = $in_data->{method};
    if ( $method eq 'login' ) {
        my $args = { in_data => $in_data, poe => $poe };
        $self->service->{login}->work($args);
    }
    elsif ( $self->{not_authorized}->{$session_id} ) {
        my $message    = "not authorized. you have to login()";
        my $out_data   = { result => "", "error" => $message };
        my $serialized = $self->formatter->serialize($out_data);
        $self->handler->{Send}->do_handle( $poe, $serialized );
    }
    else {
        my $user = $self->room->fetch_user_from_session_id($session_id);
        return unless $user;
        my $user_id = $user->user_id;
        my $args = { user_id => $user_id, in_data => $in_data, poe => $poe };
        eval { $self->service->{$method}->work($args) };
    }
}

sub unicast {
    my $self       = shift;
    my $args       = shift;
    my $user_id    = $args->{user_id};
    my $message    = $args->{message};
    my $session_id = $args->{session_id};
    eval {
        if ( !$session_id and $user_id )
        {
            my $user = $self->room->fetch_user_from_user_id($user_id);
            $session_id = $user->session_id;
        }
        $poe_kernel->post( $session_id => "Send" => $message );
    };
}

sub multicast {
    my $self    = shift;
    my $args    = shift;
    my $sender  = $args->{sender};
    my $message = $args->{message};
    my $room_id = $args->{room_id};
    my $users   = $self->room->fetch_users_from_room_id($room_id);
    for my $user (@$users) {
        my $session_id = $user->session_id;
        if ( $sender and $session_id != $sender ) {
            $poe_kernel->post( $session_id => "Send" => $message );
        }
    }
}

sub broadcast {
    my $self    = shift;
    my $args    = shift;
    my $sender  = $args->{sender};
    my $message = $args->{message};
    for my $session_id ( keys %{ $self->{sessions} } ) {
        if ( $sender and $session_id != $sender ) {
            $poe_kernel->post( $session_id => "Send" => $message );
        }
    }
}

sub regist_service {
    my $self = shift;
    while (@_) {
        my $label = shift @_;
        my $class = shift @_;
        unless ( ref($class) ) {
            $class->require or die $@;
            my $obj = $class->new( context => $self );
            $self->service->{$label} = $obj;
        }
        else {
            $self->service->{$label} = $class;
        }
    }
}

sub regist_hook {
    my $self = shift;
    while (@_) {
        my $label = shift @_;
        my $class = shift @_;
        unless ( ref($class) ) {
            $class->require or die $@;
            my $obj = $class->new( context => $self );
            $self->hook->{$label} = $obj;
        }
        else {
            $self->hook->{$label} = $class;
        }
    }
}

sub _setup {
    my $self = shift;
    $self->_load_classes;
    my $filter = POE::Filter::Line->new( Literal => "\x00" );
    if ( $self->config->{test} and $self->config->{test} == 1 ) {
        $filter = undef;
    }
    elsif ( $self->config->{test} and $self->config->{test} == 2 ) {
        Hoppy::TestFilter->require or croak $@;
        $filter = Hoppy::TestFilter->new($self);
    }

    POE::Component::Server::TCP->new(
        Alias => $self->config->{alias} || 'xmlsocketd',
        Port  => $self->config->{port}  || 10000,
        ClientConnected    => sub { $self->_tcp_handle( Connected    => @_ ) },
        ClientInput        => sub { $self->_tcp_handle( Input        => @_ ) },
        ClientDisconnected => sub { $self->_tcp_handle( Disconnected => @_ ) },
        ClientError        => sub { $self->_tcp_handle( Error        => @_ ) },

        ClientFilter => $filter,
        InlineStates => {
            Send => sub {
                $self->_tcp_handle( Send => @_ );
            },
        },
    );
    POE::Kernel->sig( INT => sub { POE::Kernel->stop } );
}

sub _load_classes {
    my $self = shift;

    # tcp handler
    {
        $self->handler( {} );
        for (qw(Input Connected Disconnected Error Send)) {
            my $class = __PACKAGE__ . '::TCPHandler::' . $_;
            $self->handler->{$_} = $class->new( context => $self );
        }
    }

    # io formatter
    {
        my $class = $self->config->{Formatter}
          || __PACKAGE__ . '::Formatter::JSON';
        $class->require or croak $@;
        $self->formatter( $class->new( context => $self ) );
    }

    # default service
    {
        $self->service( {} );
        my @services = (
            { login  => __PACKAGE__ . '::Service::Login' },
            { logout => __PACKAGE__ . '::Service::Logout' },
        );
        if ( $self->config->{regist_services} ) {
            while ( my ( $key, $value ) =
                each %{ $self->config->{regist_services} } )
            {
                push @services, { $key => $value };
            }
        }
        for (@services) {
            my ( $label, $class ) = %$_;
            $class->require or croak $@;
            $self->service->{$label} = $class->new( context => $self );
        }
    }

    # default hook
    {
        $self->hook( {} );
        my @hooks = ();
        if ( $self->config->{regist_hooks} ) {
            while ( my ( $key, $value ) =
                each %{ $self->config->{regist_hooks} } )
            {
                push @hooks, { $key => $value };
            }
        }
        for (@hooks) {
            my ( $label, $class ) = %$_;
            $class->require or croak $@;
            $self->hook->{$label} = $class->new( context => $self );
        }
    }

    # room
    {
        my $class = $self->config->{Room}
          || __PACKAGE__ . '::Room::Memory';
        $class->require or croak $@;
        $self->room( $class->new( context => $self ) );
    }
}

sub _tcp_handle {
    my $self         = shift;
    my $handler_name = shift;
    my $poe          = POE::Sugar::Args->new(@_);
    $self->handler->{$handler_name}->do_handle($poe);
}

1;
__END__

=head1 NAME

Hoppy - Flash XMLSocket Server.

=head1 SYNOPSIS

  use Hoppy;

  use MyService::Auth;
  use MyService::Chat;

  my $config = {
    alias => 'hoppy',
    port  => 12345,
    test  => 1,      # does not work POE::Filter::Line ( use it as telnet when debug phaze )
  };

  my $server = Hoppy->new(config => $config);

  $server->regist_service(
     auth => 'MyService::Auth',
     chat => 'MyService::Chat',
  );

  $server->start;

=head1 DESCRIPTION

Hoppy is a perl implementation of Flash XMLSocket Server.

=head1 METHODS

=head2 new(config => $config)

=head2 regist_service( $service_label => $service_class )

=head2 regist_hook( $hook_class => $args )

=head2 start

=head2 stop

=head2 unicast( { user_id => $user_id, messge => $message } )

=head2 multicast( { sender => $sender_session_id, room_id => $room_id, message => $message } )

=head2 broadcast( { sender => $sender_session_id, message => $message } )

=head2 dispatch($method, $params, $poe)

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
