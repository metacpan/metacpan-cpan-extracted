package JSON::RPC2::AnyEvent::Client;
use 5.008005;
use strict;
use warnings;

use utf8;
use AnyEvent::Handle;
use JSON::RPC2::Client;
use JSON::XS; # while there is no perl raw data interface in JSON::RPC2::Client

our $VERSION = "0.01";

our $AUTOLOAD;  # it's a package global

my @remappable = qw( service named listed destroy );

sub new {
   my $class = shift;
   my $self = bless {
      client => JSON::RPC2::Client->new(),
      call => 'call',
      @_,
      remappable => {},
      cb => [],
   }, $class;
   $self->{call} = 'call'       if 'listed' eq $self->{call};
   $self->{call} = 'call_named' if 'named'  eq $self->{call};
   for( @remappable ) {
      if( exists $self->{$_} ) {
          $self->{remappable}->{ $self->{$_} } = '__'.$_ 
      } else {
          $self->{remappable}->{ $_ } = '__'.$_ 
      }
   }
   $self->__connect;
   $self;
}

sub __connect {
   my $self = shift;
   $self->{handle} = new AnyEvent::Handle
      connect  => [ $self->{host}, $self->{port} ],
      on_error => sub {
         $_->("HTTP/1.0 500 $!") for @{$self->{cb}};
         $self->{handle}->destroy; # explicitly destroy handle
      },
      on_eof   => sub {
         $_->("CONNECTION CLOSED $!") for @{$self->{cb}};
         $self->{handle}->destroy; # explicitly destroy handle
      };
}

sub __named {
   my $self = shift;
   $self->{call} = 'call_named';
   $self;
}

sub __listed {
   my $self = shift;
   $self->{call} = 'call';
   $self;
}

sub __service {
   my $self = shift;
   $self->{service} = shift;
   $self;
}

sub AUTOLOAD {
   my $self = shift;

   my $method = $AUTOLOAD;
   $method =~ s/(.*):://g;

   if( exists $self->{remappable}->{$method} ) {
      $method = $self->{remappable}->{$method};
      return $self->$method( @_ );
   }

   my $cb = pop;

   push @{$self->{cb}}, $cb;

   $method = $self->{service} ? $self->{service} . '.' . $method : $method;

   my $call = $self->{call};

   my ( $json_request, $call_id ) = $self->{client}->$call( $method, @_ );

   $self->{handle}->push_write( $json_request );

   $self->{handle}->push_read( json => sub{
       my ( $handle, $hash ) = @_;
       my ( $failed, $result, $error, $call_id ) = $self->{client}->response( encode_json($hash) );
       my $cb = shift @{$self->{cb}};
       $cb->( $failed, $result, $error, $call_id );
   } );
   
   return $call_id;
}

# This DESTROY-pattern originates from AnyEvent::Handle code.
sub DESTROY {
   my ($self) = @_;
   $self->{handle}->destroy();
}

sub __destroy {
   my ($self) = @_;
   $self->DESTROY;
   %$self = ();
   bless $self, "JSON::RPC2::AnyEvent::Client::Magic::destroyed";
}

sub JSON::RPC2::AnyEvent::Client::destroyed::AUTOLOAD {
   #nop
}

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent::Client - Nonblocking JSON RPC2 client with method mapping.

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Client;

    # create connection
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        host    => "127.0.0.1",
        port    => 5555,
    );

    # call
    $rpc->rpcfn( 1, 'two', 3, sub{
        my ( $failed, $result, $error ) = @_;
        print Dumper $result if ! $failed && ! $error;
    })

    # call remote function with some configure
    $rpc->service('agent')->listed()->remote_function( 'param1', 'param2', sub{
        my ( $failed, $result, $error ) = @_;
    })

    # more arguments desctibed below
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        host    => "127.0.0.1",
        port    => 5555,
        service => 'agent',
        call    => 'listed' || 'named',
        service => '_service',  # rename any this module methods
    );

    # destroy rpc connection when done
    $rpc->destroy;


=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Client is JSON RPC2 client, currently with
tcp transport, handled by L<AnyEvent::Handle>, and remote
functions mapping to local client functions, and based on
JSON RPC2 implementation L<JSON::RPC2::Client>.

=head1 METHODS

=over 4

=item $rpc = B<new> JSON::RPC2::AnyEvent::Client host=>'example.com', ...

The constructor supports these arguments (all as C<< key => value >> pairs).

=over 4

=item host => 'example.com'

The hostname or ip address.

=item port => 5555

The tcp port number

=item service => 'agent'

Set the service name, it will be prefix before remote function
name with dot as separator. So if service is 'agent' then call
like $rpc->remote_fn(), then C<agent.remote_fn> will be called

=item call => 'listed' || 'named'

Type of RPC call, default listed.

=item any_method_name => 'remap_method_name'

If remote server have method with same name as in this module,
it is possible to rename this module C<method_name> to another
name C<remap_method_name>

=back

=item B<service> ( "service_name" )

Set remote service name, if undef - then no service name used.

=item B<listed>

RPC listed call type will be used.

=item B<named>

RPC named call type will be used.

=item B<any other name> ( $param1, $param2, ..., $cb )

Any method name will called via RPC on remote server. 
Last param must be event handler cb(). 
There is params of cb ( $failed, $result, $error );
Where $result is server responce, valid only when there
is no fail or error.

=back


=head1 DEPENDENCIES

 L<JSON::XS>
 L<AnyEvent::Handle>;
 L<JSON::RPC2::Client>;

=head1 LICENSE

Copyright (C) Serguei Okladnikov.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Serguei Okladnikov E<lt> oklas@cpan.org E<gt>

=cut

