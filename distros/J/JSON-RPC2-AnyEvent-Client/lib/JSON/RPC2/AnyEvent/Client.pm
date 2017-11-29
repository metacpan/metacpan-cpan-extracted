package JSON::RPC2::AnyEvent::Client;
use 5.008005;
use strict;
use warnings;

use utf8;
use AnyEvent::Handle;
use AnyEvent::HTTP;
use JSON::RPC2::Client;

our $VERSION = "0.03";

our $AUTOLOAD;  # it's a package global

my @remappable = qw( service named listed destroy );

sub new {
   my $class = shift;
   my $self = bless {
      client => JSON::RPC2::Client->new(),
      call => 'call',
      @_,
      remappable => {},
      cb => {},
      on_error => sub{ warn shift . ' at ' . join(' ',caller) }
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
   if ( $self->{url} ) {
      $self->{request_fn} = \&JSON::RPC2::AnyEvent::Client::__request_http;
   } else {
      $self->__connect_tcp;
      $self->{request_fn} = \&JSON::RPC2::AnyEvent::Client::__request_tcp;
   }
   $self;
}

sub __connect_tcp {
   my $self = shift;
   return if $self->{http};
   $self->{handle} = new AnyEvent::Handle
      connect  => [ $self->{host}, $self->{port} ],
      on_error => sub {
         my $url = 'url '.($self->{host}||'').':'.($self->{port}||'').' ';
         $self->__fail_error($url . $!);
         $self->{handle}->destroy if $self->{handle}; # explicitly destroy
      },
      on_eof   => sub {
         my $url = 'url '.($self->{host}||'').':'.($self->{port}||'').' ';
         $self->__fail_error("$url CONNECTION CLOSED $!");
         $self->{handle}->destroy if $self->{handle}; # explicitly destroy
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

sub __fail_error {
   my ( $self, $error ) = @_;
   $self->{on_error}->( $error );
   foreach my $call_id ( keys %{$self->{cb}} ) {
      my $cb = delete $self->{cb}->{$call_id};
      $cb->( $error );
   }
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

   $method = $self->{service} ? $self->{service} . '.' . $method : $method;

   my $call = $self->{call};

   my ( $json_request, $call_id ) = $self->{client}->$call( $method, @_ );

   $self->{cb}->{$call_id} = $cb;

   $self->{request_fn}->( $self, $json_request );

   return $call_id;
}

sub __request_tcp {
   my ( $self, $json_request ) = @_;

   $self->{handle}->push_write( $json_request );

   $self->{handle}->push_read( json => sub{
      my ( $handle, $hash ) = @_;
      my ( $failed, $result, $error, $call_id ) = $self->{client}->response( $hash );
      return $self->__error( $failed ) if $failed;
      $self->__do_callback( $call_id, $failed, $result, $error );
   } );
}

sub __request_http {
   my ( $self, $json_request ) = @_;

   http_post $self->{url}, $json_request, sub {
      my ( $resp, $hdr ) = @_;

      unless ( $hdr->{Status} =~ /^2/ ) {
         return $self->__error( "$hdr->{Status} $hdr->{Reason}" );
      }

      my ( $failed, $result, $error, $call_id ) =
         $self->{client}->response( $resp );

      return $self->__error( $failed ) if $failed;

      $self->__do_callback( $call_id, $failed, $result, $error );
   };
}

sub __do_callback {
   my ( $self, $call_id, $failed, $result, $error ) = @_;
   my $cb = delete $self->{cb}->{$call_id};
   if( $self->{simplify_errors} ) {
      my $err = $failed || $error && $error->{message};
      $cb->( $err, $result );
   } else {
      $cb->( $failed, $result, $error );
   }
}

# This DESTROY-pattern originates from AnyEvent::Handle code.
sub DESTROY {
   my ($self) = @_;
   $self->{handle}->destroy() if $self->{handle};
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

JSON::RPC2::AnyEvent::Client - Asynchronous nonblocking JSON RPC2 client with method mapping

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Client;

    # create tcp connection
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        host     => "127.0.0.1",
        port     => 5555,
        on_error => sub{ die $_[0] } 
    );

    # call
    $rpc->sum( 1, 2, sub{
        my ( $failed, $result, $error ) = @_;
        print $result unless $failed || $error;
    })

    # call remote function with simple configure
    $rpc->service('agent')->listed()->remote_function( 'param1', 'param2', sub{
        my ( $failed, $result, $error ) = @_;
    })

    # some more constructor arguments
    my $rpc = JSON::RPC2::AnyEvent::Client->new(
        url     => "https://$host:$port/api", # http/https transport
        service => 'agent',
        call    => 'listed' || 'named',
        service => '_service',  # rename any this module methods
    );

    # destroy rpc connection when done
    $rpc->destroy;


=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Client is JSON RPC2 client, with
tcp/http/https transport. Remote functions is mapped to local
client object methods. For example remote function fn(...) is
called as $c->fn(...,cb). Params of function is params of remote
functions with additional one at the end of param list.
Additional last param is result handler soubroutine.

Implementation is based on JSON RPC2 implementation
L<JSON::RPC2::Client>. Transport implementation is based
on L<AnyEvent::Handle> for tcp, and on L<AnyEvent::HTTP>
for http/https.

The 'tcp' implementation use persistent connection, that make
tcp connection at object creation and use it all object life time.
The http/https persistence is AnyEvent::HTTP implementation
dependent and currently it is not persistent for idempotent
requsests (JSON RPC2 need POST requset). See description of
'persistent' and 'keepalive' params of L<AnyEvent::HTTP>.

=head1 METHODS

=over 4

=item $rpc = B<new> JSON::RPC2::AnyEvent::Client host=>'example.com', ...

The constructor supports arguments as C<< key => value >> pairs.

=over 4

=item host => 'example.com'

The hostname or ip address. This enable tcp transport.
The special value "unix/" used to connect to unix domain
socket. Current version support unix domain socket only
for 'tcp' transport.

=item port => 5555

The tcp port number or unix domain socket path. Used togather
with 'host' param.

=item on_error = sub{ die $_[0] }

The transport error handler callback. Remote RPC service errors
does not mapped to this handler. This error also will emit
all alredy waited for result callback handlers.

=item url => "https://$host:$port/api/rpc"

The url of requst. This enables http/https transport.

=item service => 'agent'

Set the service name, it will be prefix before remote function
name with dot as separator. So if service is 'agent' then call
like $rpc->remote_fn(), then C<agent.remote_fn> will be called

=item call => 'listed' || 'named'

Type of RPC call, default listed.

=item simplify_errors => 1

This option change callback api from two error to one by unify
transport error with text error message from remote server.
This option allow to simplify result callback writing but make
less compatible with rpc protocol. It also make result callback
impossible to recognize type of error is it transport or remote.
This is usable for simple applications. See result callback
handler for more info.

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
Last param must be result handler callback cb(). 

=back

=head1 RESULT HANDLER CALLBACK

The result callback handler is a soubroutine that called
when rpc function is called and result is arrived or
an error occured. There three param of callback is
C<< ( $fail, $result, $error ); >>

The $fail is transport error. It is string that contain
description of communication or data decoding error.

The $result is server responce, valid only when there
is no fail or error.

The $error is described in rpc protocol standart remote
server error responce. It is valid only when no fail.

There is special case for simple applications enabled by
C<< simplify_errors >> constructor argument. The result callback
at this case have only two params. First param is transport
error if any or text error message arrived from remote service.
Simplified callback prototype is:
C<< ( $error, $result ); >>

=head1 DEPENDENCIES

=over 8

=item L<AnyEvent::Handle>;

=item L<AnyEvent::HTTP>;

=item L<JSON::RPC2::Client>;

=item L<JSON::XS>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Serguei Okladnikov E<lt>oklaspec@gmail.comE<gt>

=cut

