#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Server;

use Event::RPC;
use Event::RPC::Connection;
use Event::RPC::LogConnection;
use Event::RPC::Message::Negotiate;

use Carp;
use strict;
use utf8;

use IO::Socket::INET;
use Sys::Hostname;

sub get_host                    { shift->{host}                         }
sub get_port                    { shift->{port}                         }
sub get_name                    { shift->{name}                         }
sub get_loop                    { shift->{loop}                         }
sub get_classes                 { shift->{classes}                      }
sub get_singleton_classes       { shift->{singleton_classes}            }
sub get_loaded_classes          { shift->{loaded_classes}               }
sub get_clients_connected       { shift->{clients_connected}            }
sub get_log_clients_connected   { shift->{log_clients_connected}        }
sub get_logging_clients         { shift->{logging_clients}              }
sub get_logger                  { shift->{logger}                       }
sub get_start_log_listener      { shift->{start_log_listener}           }
sub get_objects                 { shift->{objects}                      }
sub get_rpc_socket              { shift->{rpc_socket}                   }
sub get_ssl                     { shift->{ssl}                          }
sub get_ssl_key_file            { shift->{ssl_key_file}                 }
sub get_ssl_cert_file           { shift->{ssl_cert_file}                }
sub get_ssl_passwd_cb           { shift->{ssl_passwd_cb}                }
sub get_ssl_opts                { shift->{ssl_opts}                     }
sub get_auth_required           { shift->{auth_required}                }
sub get_auth_passwd_href        { shift->{auth_passwd_href}             }
sub get_auth_module             { shift->{auth_module}                  }
sub get_listeners_started       { shift->{listeners_started}            }
sub get_connection_hook         { shift->{connection_hook}              }
sub get_load_modules            { shift->{load_modules}                 }
sub get_auto_reload_modules     { shift->{auto_reload_modules}          }
sub get_active_connection       { shift->{active_connection}            }
sub get_message_formats         { shift->{message_formats}              }
sub get_insecure_msg_fmt_ok     { shift->{insecure_msg_fmt_ok}          }

sub set_host                    { shift->{host}                 = $_[1] }
sub set_port                    { shift->{port}                 = $_[1] }
sub set_name                    { shift->{name}                 = $_[1] }
sub set_loop                    { shift->{loop}                 = $_[1] }
sub set_classes                 { shift->{classes}              = $_[1] }
sub set_singleton_classes       { shift->{singleton_classes}    = $_[1] }
sub set_loaded_classes          { shift->{loaded_classes}       = $_[1] }
sub set_clients_connected       { shift->{clients_connected}    = $_[1] }
sub set_log_clients_connected   { shift->{log_clients_connected}= $_[1] }
sub set_logging_clients         { shift->{logging_clients}      = $_[1] }
sub set_logger                  { shift->{logger}               = $_[1] }
sub set_start_log_listener      { shift->{start_log_listener}   = $_[1] }
sub set_objects                 { shift->{objects}              = $_[1] }
sub set_rpc_socket              { shift->{rpc_socket}           = $_[1] }
sub set_ssl                     { shift->{ssl}                  = $_[1] }
sub set_ssl_key_file            { shift->{ssl_key_file}         = $_[1] }
sub set_ssl_cert_file           { shift->{ssl_cert_file}        = $_[1] }
sub set_ssl_passwd_cb           { shift->{ssl_passwd_cb}        = $_[1] }
sub set_ssl_opts                { shift->{ssl_opts}             = $_[1] }
sub set_auth_required           { shift->{auth_required}        = $_[1] }
sub set_auth_passwd_href        { shift->{auth_passwd_href}     = $_[1] }
sub set_auth_module             { shift->{auth_module}          = $_[1] }
sub set_listeners_started       { shift->{listeners_started}    = $_[1] }
sub set_connection_hook         { shift->{connection_hook}      = $_[1] }
sub set_load_modules            { shift->{load_modules}         = $_[1] }
sub set_auto_reload_modules     { shift->{auto_reload_modules}  = $_[1] }
sub set_active_connection       { shift->{active_connection}    = $_[1] }
sub set_message_formats         { shift->{message_formats}      = $_[1] }
sub set_insecure_msg_fmt_ok     { shift->{insecure_msg_fmt_ok}  = $_[1] }

my $INSTANCE;
sub instance { $INSTANCE }

sub get_max_packet_size {
    return Event::RPC::Message->get_max_packet_size;
}

sub set_max_packet_size {
    my $class = shift;
    my ($value) = @_;
    Event::RPC::Message->set_max_packet_size($value);
}

sub new {
    my $class = shift;
    my %par = @_;
    my  ($host, $port, $classes, $name, $logger, $start_log_listener) =
    @par{'host','port','classes','name','logger','start_log_listener'};
    my  ($ssl, $ssl_key_file, $ssl_cert_file, $ssl_passwd_cb, $ssl_opts) =
    @par{'ssl','ssl_key_file','ssl_cert_file','ssl_passwd_cb','ssl_opts'};
    my  ($auth_required, $auth_passwd_href, $auth_module, $loop) =
    @par{'auth_required','auth_passwd_href','auth_module','loop'};
    my  ($connection_hook, $auto_reload_modules) =
    @par{'connection_hook','auto_reload_modules'};
    my  ($load_modules, $message_formats, $insecure_msg_fmt_ok) =
    @par{'load_modules','message_formats','insecure_msg_fmt_ok'};

    $name ||= "Event-RPC-Server";
    $insecure_msg_fmt_ok = 1 unless defined $insecure_msg_fmt_ok;

    #-- for backwards compatibility 'load_modules' defaults to 1
    if ( !exists $par{load_modules} ) {
        $load_modules = 1;
    }

    if ( not $loop ) {
        foreach my $impl ( qw/AnyEvent Event Glib/ ) {
            $loop = "Event::RPC::Loop::$impl";
            eval "use $loop";
            if ( $@ ) {
                $loop = undef;
            }
            else {
                $loop = $loop->new;
                last;
            }
        }
        die "It seems no supported event loop module is installed"
            unless $loop;
    }

    my $self = bless {
        host                    => $host,
        port                    => $port,
        name                    => $name,
        classes                 => $classes,
        singleton_classes       => {},
        logger                  => $logger,
        start_log_listener      => $start_log_listener,
        loop                    => $loop,

        ssl                     => $ssl,
        ssl_key_file            => $ssl_key_file,
        ssl_cert_file           => $ssl_cert_file,
        ssl_passwd_cb           => $ssl_passwd_cb,
        ssl_opts                => $ssl_opts,

        auth_required           => $auth_required,
        auth_passwd_href        => $auth_passwd_href,
        auth_module             => $auth_module,

        load_modules            => $load_modules,
        auto_reload_modules     => $auto_reload_modules,
        connection_hook         => $connection_hook,

        message_formats         => $message_formats,
        insecure_msg_fmt_ok     => $insecure_msg_fmt_ok,

        rpc_socket              => undef,
        loaded_classes          => {},
        objects                 => {},
        logging_clients         => {},
        clients_connected       => 0,
        listeners_started       => 0,
        log_clients_connected   => 0,
        active_connection       => undef,
    }, $class;

    $INSTANCE = $self;

    $self->log ($self->get_name." started");

    return $self;
}

sub DESTROY {
    my $self = shift;

    my $rpc_socket = $self->get_rpc_socket;
    close ($rpc_socket) if $rpc_socket;

    1;
}

sub probe_message_formats {
    my $class = shift;
    my ($user_supplied_formats, $insecure_msg_fmt_ok) = @_;

    my $order_lref      = Event::RPC::Message::Negotiate->message_format_order;
    my $modules_by_name = Event::RPC::Message::Negotiate->known_message_formats;

    my %probe_formats;
    if ( $user_supplied_formats ) {
        @probe_formats{@{$user_supplied_formats}} =
            (1) x @{$user_supplied_formats};
    }
    else {
        %probe_formats = %{$modules_by_name};
    }

    #-- By default we probe all supported formats, but
    #-- not Storable. User has to activate this explicitely.
    if ( not $insecure_msg_fmt_ok ) {
        delete $probe_formats{STOR};
    }

    Event::RPC::Message::Negotiate->set_storable_fallback_ok($insecure_msg_fmt_ok);

    my @supported_formats;
    foreach my $name ( @{$order_lref} ) {
        next unless $probe_formats{$name};

        my $module = $modules_by_name->{$name};
        eval "use $module";

        push @supported_formats, $name unless $@;
    }

    return \@supported_formats;
}

sub setup_listeners {
    my $self = shift;

    #-- Listener options
    my $host      = $self->get_host;
    my $port      = $self->get_port;
    my @LocalHost = $host ? ( LocalHost => $host ) : ();
    $host ||= "*";

    #-- get event loop manager
    my $loop = $self->get_loop;

    #-- setup rpc listener
    my $rpc_socket;
    if ( $self->get_ssl ) {
        eval { require IO::Socket::SSL };
        croak "SSL requested, but IO::Socket::SSL not installed" if $@;
        croak "ssl_key_file not set"  unless $self->get_ssl_key_file;
        croak "ssl_cert_file not set" unless $self->get_ssl_cert_file;

        my $ssl_opts = $self->get_ssl_opts;

        $rpc_socket = IO::Socket::SSL->new (
            Listen          => SOMAXCONN,
            @LocalHost,
            LocalPort       => $port,
            Proto           => 'tcp',
            ReuseAddr       => 1,
            SSL_key_file    => $self->get_ssl_key_file,
            SSL_cert_file   => $self->get_ssl_cert_file,
            SSL_passwd_cb   => $self->get_ssl_passwd_cb,
            ($ssl_opts?%{$ssl_opts}:()),
        ) or die "can't start SSL RPC listener: $IO::Socket::SSL::ERROR";
    }
    else {
        $rpc_socket = IO::Socket::INET->new (
            Listen    => SOMAXCONN,
            @LocalHost,
            LocalPort => $port,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "can't start RPC listener: $!";
    }

    $self->set_rpc_socket($rpc_socket);

    $loop->add_io_watcher (
        fh      => $rpc_socket,
        poll    => 'r',
        cb      => sub { $self->accept_new_client($rpc_socket); 1 },
        desc    => "rpc listener port $port",
    );

    if ( $self->get_ssl ) {
        $self->log ("Started SSL RPC listener on port $host:$port");
    } else {
        $self->log ("Started RPC listener on $host:$port");
    }

    # setup log listener
    if ( $self->get_start_log_listener ) {
        my $log_socket = IO::Socket::INET->new (
            Listen    => SOMAXCONN,
            LocalPort => $port + 1,
            @LocalHost,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "can't start log listener: $!";

        $loop->add_io_watcher (
            fh      => $log_socket,
            poll    => 'r',
            cb      => sub { $self->accept_new_log_client($log_socket); 1 },
            desc    => "log listener port ".($port+1),
        );

        $self->log ("Started log listener on $host:".($port+1));
    }

    $self->determine_singletons;

    $self->set_listeners_started(1);

    1;
}

sub setup_auth_module {
    my $self = shift;

    #-- Exit if no auth is required or setup already
    return if not $self->get_auth_required;
    return if     $self->get_auth_module;

    #-- Default to Event::RPC::AuthPasswdHash
    require Event::RPC::AuthPasswdHash;

    #-- Setup an instance
    my $passwd_href = $self->get_auth_passwd_href;
    my $auth_module = Event::RPC::AuthPasswdHash->new ($passwd_href);
    $self->set_auth_module($auth_module);

    1;
}

sub start {
    my $self = shift;

    $self->setup_listeners
        unless $self->get_listeners_started;

    $self->setup_auth_module;

    #-- Filter unsupported message formats
    $self->set_message_formats(
        $self->probe_message_formats(
            $self->get_message_formats,
            $self->get_insecure_msg_fmt_ok
        )
    );

    my $loop = $self->get_loop;

    $self->log ("Enter main loop using ".ref($loop));

    $loop->enter;

    $self->log ("Server stopped");

    1;
}

sub stop {
    my $self = shift;

    $self->get_loop->leave;

    1;
}

sub determine_singletons {
    my $self = shift;

    my $classes = $self->get_classes;
    my $singleton_classes = $self->get_singleton_classes;

    foreach my $class ( keys %{$classes} ) {
        foreach my $method ( keys %{$classes->{$class}} ) {
            # check for singleton returner
            if ( $classes->{$class}->{$method} eq '_singleton' ) {
                # change to constructor
                $classes->{$class}->{$method} = '_constructor';
                # track that this class is a singleton
                $singleton_classes->{$class} = 1;
                last;
            }
        }
    }

    1;
}

sub accept_new_client {
    my $self = shift;
    my ($rpc_socket) = @_;

    my $client_socket = $rpc_socket->accept or return;

    Event::RPC::Connection->new ($self, $client_socket);

    $self->set_clients_connected ( 1 + $self->get_clients_connected );

    1;
}

sub accept_new_log_client {
    my $self = shift;
    my ($log_socket) = @_;

    my $client_socket = $log_socket->accept or return;

    my $log_client =
        Event::RPC::LogConnection->new($self, $client_socket);

    $self->set_log_clients_connected ( 1 + $self->get_log_clients_connected );
    $self->get_logging_clients->{$log_client->get_cid} = $log_client;
    $self->get_logger->add_fh($client_socket)
        if $self->get_logger;

    $self->log(2, "New log client connected");

    1;
}

sub load_class {
    my $self = shift;
    my ($class) = @_;

    Event::RPC::Connection->new ($self)->load_class($class);

    return $class;
}

sub log {
    my $self = shift;
    my $logger = $self->get_logger;
    return unless $logger;
    $logger->log(@_);
    1;
}

sub remove_object {
    my $self = shift;
    my ($object) = @_;

    my $objects = $self->get_objects;

    if ( not $objects->{"$object"} ) {
        warn "Object $object not registered";
        return;
    }

    delete $objects->{"$object"};

    $self->log(5, "Object '$object' removed");

    1;
}

sub register_object {
    my $self = shift;
    my ($object, $class) = @_;

    my $objects = $self->get_objects;

    my $refcount;
    if ( $objects->{"$object"} ) {
        $refcount = ++$objects->{"$object"}->{refcount};
    } else {
        $refcount = 1;
        $objects->{"$object"} = {
            object   => $object,
            class    => $class,
            refcount => 1,
        };
    }

    $self->log(5, "Object '$object' registered. Refcount=$refcount");

    1;
}

sub deregister_object {
    my $self = shift;
    my ($object) = @_;

    my $objects = $self->get_objects;

    if ( not $objects->{"$object"} ) {
        warn "Object $object not registered";
        return;
    }

    my $refcount = --$objects->{"$object"}->{refcount};

    my ($class) = split(/=/, $object);
    if ( $self->get_singleton_classes->{$class} ) {
        # never deregister singletons
        $self->log(4, "Skip deregistration of singleton '$object'");
        return;
    }

    $self->log(5, "Object '$object' deregistered. Refcount=$refcount");

    $self->remove_object($object) if $refcount == 0;

    1;
}

sub print_object_register {
    my $self = shift;

    print "-"x70,"\n";

    my $objects = $self->get_objects;
    foreach my $oid ( sort keys %{$objects} ) {
        print "$oid\t$objects->{$oid}->{refcount}\n";
    }

    1;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Server - Simple API for event driven RPC servers

=head1 SYNOPSIS

  use Event::RPC::Server;
  use My::TestModule;

  my $server = Event::RPC::Server->new (
      #-- Required arguments
      port               => 8888,
      classes            => {
        "My::TestModule" => {
          new      => "_constructor",
          get_data => 1,
          set_data => 1,
          clone    => "_object",
        },
      },

      #-- Optional arguments
      name                => "Test server",
      logger              => Event::RPC::Logger->new(),
      start_log_listener  => 1,

      ssl                 => 1
      ssl_key_file        => "server.key",
      ssl_cert_file       => "server.crt",
      ssl_passwd_cb       => sub { "topsecret" },
      ssl_opts            => { ... },

      auth_required       => 1,
      auth_passwd_href    => { $user => Event::RPC->crypt($user,$pass) },
      auth_module         => Your::Own::Auth::Module->new(...),

      loop                => Event::RPC::Loop::Event->new(),
      
      host                => "localhost",
      load_modules        => 1,
      auto_reload_modules => 1,
      connection_hook     => sub { ... },

      message_formats     => [qw/ SERL CBOR JSON STOR /],
      insecure_msg_fmt_ok => 1,
  );

  $server->set_max_packet_size(2*1024*1024*1024);
  $server->start;

  # and later from inside your server implementation
  Event::RPC::Server->instance->stop;

=head1 DESCRIPTION

Use this module to add a simple to use RPC mechanism to your event
driven server application.

Just create an instance of the Event::RPC::Server class with a
bunch of required settings. Then enter the main event loop through
it, or take control over the main loop on your own if you like
(refer to the MAINLOOP chapter for details).

General information about the architecture of Event::RPC driven
applications is collected in the Event::RPC manpage.

=head1 CONFIGURATION OPTIONS

All options described here may be passed to the new() constructor of
Event::RPC::Server. As well you may set or modify them using set_OPTION style
mutators, but not after start() or setup_listeners() was called!
All options may be read using get_OPTION style accessors.

=head2 REQUIRED OPTIONS

If you just pass the required options listed beyond you have
a RPC server which listens to a network port and allows everyone
connecting to it to access a well defined list of classes and methods
resp. using the correspondent server objects.

There is no authentication or encryption active in this minimal
configuration, so aware that this may be a big security risk!
Adding security is easy, refer to the chapters about SSL and
authentication.

These are the required options:

=over 4

=item B<port>

TCP port number of the RPC listener.

=item B<classes>

This is a hash ref with the following structure:

  classes => {
    "Class1" => {
      new             => "_constructor",
      simple_method   => 1,
      object_returner => "_object",
    },
    "Class2" => { ... },
    ...
  },

Each class which should be accessible for clients needs to
be listed here at the first level, assigned a hash of methods
allowed to be called. Event::RPC disuinguishes three types
of methods by classifying their return value:

=over 4

=item B<Constructors>

A constructor method creates a new object of the corresponding class
and returns it. You need to assign the string "_constructor" to
the method entry to mark a method as a constructor.

=item B<Singleton constructors>

For singleton classes the method which returns the singleton
instance should be declared with "_singleton". This way the server
takes care that references get never destroyed on server side.

=item B<Simple methods>

What's simple about these methods is their return value: it's
a scalar, array, hash or even any complex reference structure
(Ok, not simple anymore ;), but in particular it returns B<NO> objects,
because this needs to handled specially (see below).

Declare simple methods by assigning 1 in the method declaration.

=item B<Object returners>

Methods which return objects need to be declared by assigning
"_object" to the method name here. They're not bound to return
just one scalar object reference and may return an array or list
reference with a bunch of objects as well.

=back

=back

=head2 SSL OPTIONS

The client/server protocol of Event::RPC is not encrypted by default,
so everyone listening on your network can read or even manipulate
data. To prevent this efficiently you can enable SSL encryption.
Event::RPC uses the IO::Socket::SSL Perl module for this.

First you need to generate a server key and certificate for your server
using the openssl command which is part of the OpenSSL distribution,
e.g. by issueing these commands (please refer to the manpage of openssl
for details - this is a very rough example, which works in general, but
probably you want to tweak some parameters):

  % openssl genrsa -des3 -out server.key 1024
  % openssl req -new -key server.key -out server.csr
  % openssl x509 -req -days 3600 -in server.csr \
            -signkey server.key -out server.crt

After executing these commands you have the following files

  server.crt
  server.key
  server.csr

Event::RPC needs the first two of them to operate with SSL encryption.

To enable SSL encryption you need to pass the following options
to the constructor:

=over 4

=item B<ssl>

The ssl option needs to be set to 1.

=item B<ssl_key_file>

This is the filename of the server.key you generated with
the openssl command.

=item B<ssl_cert_file>

This is the filename of the server.crt file you generated with
the openssl command.

=item B<ssl_passwd_cb>

Your server key is encrypted with a password you entered during the
key creation process described above. This callback must return
it. Depending on how critical your application is you probably must
request the password from the user during server startup or place it
into a more or less secured file. For testing purposes you
can specify a simple anonymous sub here, which just returns the
password, e.g.

  ssl_passwd_cb => sub { return "topsecret" }

But note: having the password in plaintext in your program code is
insecure!

=item B<ssl_opts>

This optional parameter takes a hash reference of options
passed to IO::Socket::SSL->new(...) to have more control
over the server SSL listener. 

=back

=head2 AUTHENTICATION OPTIONS

SSL encryption is fine, now it's really hard for an attacker to
listen or modify your network communication. But without any further
configuration any user on your network is able to connect to your
server. To prevent this users resp. connections to your server
needs to be authenticated somehow.

Since version 0.87 Event::RPC has an API to delegate authentication
tasks to a module, which can be implemented outside Event::RPC.
To be compatible with prior releases it ships the module
Event::RPC::AuthPasswdHash which implements the old behaviour
transparently.

This default implementation is a simple user/password based model. For now
this controls just the right to connect to your server, so knowing
one valid user/password pair is enough to access all exported methods
of your server. Probably a more differentiated model will be added later
which allows granting access to a subset of exported methods only
for each user who is allowed to connect.

The following options control the authentication:

=over 4

=item B<auth_required>

Set this to 1 to enable authentication and nobody can connect your server
until he passes a valid user/password pair.

=item B<auth_passwd_href>

If you like to use the builtin Event::RPC::AuthPasswdHash module
simply set this attribute. If you decide to use B<auth_module>
(explained beyound) it's not necessary.

B<auth_passwd_href> is a hash of valid user/password pairs. The password
stored here needs to be encrypted using Perl's crypt() function, using
the username as the salt.

Event::RPC has a convenience function for generating such a crypted
password, although it's currently just a 1:1 wrapper around Perl's
builtin crypt() function, but probably this changes someday, so better
use this method:

  $crypted_pass = Event::RPC->crypt($user, $pass);

This is a simple example of setting up a proper B<auth_passwd_href> with
two users:

  auth_passwd_href => {
    fred => Event::RPC->crypt("fred", $freds_password),
    nick => Event::RPC->crypt("nick", $nicks_password),
  },

=item B<auth_module>

If you like to implement a more complex authentication method yourself
you may set the B<auth_module> attribute to an instance of your class.
For now your implementation just needs to have this method:

  $auth_module->check_credentials($user, $pass)

Aware that $pass is encrypted as explained above, so your original
password needs to by crypted using Event::RPC->crypt as well, at
least for the comparison itself.

=back

B<Note:> you can use the authentication module without SSL but aware that
an attacker listening to the network connection will be able to grab
the encrypted password token and authenticate himself with it to the
server (replay attack). Probably a more sophisticated challenge/response
mechanism will be added to Event::RPC to prevent this. But you definitely
should use SSL encryption in a critical environment anyway, which renders
grabbing the password from the net impossible.

=head2 LOGGING OPTIONS

Event::RPC has some logging abilities, primarily for debugging purposes.
It uses a B<logger> for this, which is an object implementing the
Event::RPC::Logger interface. The documentation of Event::RPC::Logger
describes this interface and Event::RPC's logging facilities in general.

=over 4

=item B<logger>

To enable logging just pass such an Event::RPC::Logger object to the
constructor.

=item B<start_log_listener>

Additionally Event::RPC can start a log listener on the server's port
number incremented by 1. All clients connected to this port (e.g. by
using telnet) get the server's log output.

Note: currently the logging port supports neither SSL nor authentication,
so be careful enabling the log listener in critical environments.

=back

=head2 MAINLOOP OPTIONS

Event::RPC derived it's name from the fact that it follows the event
driven paradigm. There are several toolkits for Perl which allow
event driven software development. Event::RPC has an abstraction layer
for this and thus should be able to work with any toolkit.

=over 4

=item B<loop>

This option takes an object of the loop abstraction layer you
want to use. Currently the following modules are implemented:

  Event::RPC::Loop::AnyEvent  Use the AnyEvent module
  Event::RPC::Loop::Event     Use the Event module
  Event::RPC::Loop::Glib      Use the Glib module

If B<loop> isn't set, Event::RPC::Server tries all supported modules
in a row and aborts the program, if no module was found.

More modules will be added in the future. If you want to implement one
just take a look at the code in the modules above: it's really
easy and I appreciate your patch. The interface is roughly described
in the documentation of Event::RPC::Loop.

=back

If you use the Event::RPC->start() method as described in the SYNOPSIS
Event::RPC will enter the correspondent main loop for you. If you want
to have full control over the main loop, use this method to setup
all necessary Event::RPC listeners:

  $rpc_server->setup_listeners();

and manage the main loop stuff on your own.

=head2 MESSAGE FORMAT OPTIONS

Event::RPC supports different CPAN modules for data serialisation,
named "message formats" here:

  SERL -- Sereal::Encoder, Sereal::Decoder
  CBOR -- CBOR::XS
  JSON -- JSON::XS
  STOR -- Storable

Server and client negotiate automatically which format is
best to use but you can manipulate this behaviour with the
following options:

=over 4

=item B<message_formats>

This takes an array of format identifiers from the list
above. Event::RPC::Server will only use / accept these
formats.

=item B<insecure_msg_fmt_ok>

The Storable module is known to be insecure. But for
backward compatibility reasons Event::RPC::Server accepts
clients which can't offer anything but Storable. You can
prevent that by setting this option explicitely to 0. It's
enabled by default.

=back

=head2 MISCELLANEOUS OPTIONS

=over 4

=item B<host>

By default the network listeners are bound to all interfaces
in the system. Use the host option to bind to a specific
interface, e.g. "localhost" if you efficiently want to prevent
network clients from accessing your server.

=item B<load_modules>

Control whether the class module files should be loaded
automatically when first accesed by a client. This options
defaults to true, for backward compatibility reasons.

=item B<auto_reload_modules>

If this option is set Event::RPC::Server will check on each
method call if the corresponding module changed on disk and
reloads it automatically. Of course this has an effect on
performance, but it's very useful during development. You
probably shouldn't enable this in production environments.

=item B<connection_hook>

This callback is called on each connection / disconnection
with two arguments: the Event::RPC::Connection object and
a string containing either "connect" or "disconnect" depending
what's currently happening with this connection.

=back

=head1 METHODS

The following methods are publically available:

=over 4

=item Event::RPC::Server->B<instance>

This returns the latest created Event::RPC::Server
instance (usually you have only one instance in one program).

=item $rpc_server->B<start>

Start the mainloop of your Event::RPC::Server.

=item $rpc_server->B<stop>

Stops the mainloop which usually means, that the server exits,
as long you don't do more sophisticated mainloop stuff by your own.

=item $rpc_server->B<setup_listeners>

This method initializes all networking listeners needed for
Event::RPC::Server to work, using the configured loop module.
Use this method if you don't use the start() method but manage
the mainloop on your own.

=item $rpc_server->B<log> ( [$level,] $msg )

Convenience method for logging. It simply passes the arguments
to the configured logger's log() method.

=item $rpc_server->B<get_clients_connected>

Returns the number of currently connected Event::RPC clients.

=item $rpc_server->B<get_log_clients_connected>

Returns the number of currently connected logging clients.

=item $rpc_server->B<get_active_connection>

This returns the currently active Event::RPC::Connection object
representing the connection resp. the client which currently 
requests method invocation. This is undef if no client call
is active.

=item $rpc_client->B<set_max_packet_size> ( $bytes )

By default Event::RPC does not handle network packages which
exceed 2 GB in size (was 4 MB with version 1.04 and earlier).

You can change this value using this method at any time,
but 4 GB is the maximum. An attempt of the server to send a
bigger packet will be aborted and reported as an exception
on the client and logged as an error message on the server.

Note: you have to set the same value on client and server side!

=item $rpc_client->B<get_max_packet_size>

Returns the currently active max packet size.

=back

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
