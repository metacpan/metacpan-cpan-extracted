package Event::RPC::Connection;

use strict;
use utf8;

use Carp;

use Event::RPC::Message::Negotiate;

#-- This can be changed for testing purposes e.g. to simulate
#-- old servers which don't perform any format negotitation.
$Event::RPC::Server::DEFAULT_MESSAGE_FORMAT = "Event::RPC::Message::Negotiate";

my $CONNECTION_ID;

sub get_cid                     { shift->{cid}                          }
sub get_sock                    { shift->{sock}                         }
sub get_server                  { shift->{server}                       }

sub get_classes                 { shift->{server}->{classes}            }
sub get_loaded_classes          { shift->{server}->{loaded_classes}     }
sub get_objects                 { shift->{server}->{objects}            }
sub get_client_oids             { shift->{client_oids}                  }

sub get_message_format          { shift->{message_format}               }
sub get_watcher                 { shift->{watcher}                      }
sub get_write_watcher           { shift->{write_watcher}                }
sub get_message                 { shift->{message}                      }
sub get_is_authenticated        { shift->{is_authenticated}             }
sub get_auth_user               { shift->{auth_user}                    }

sub set_message_format          { shift->{message_format}       = $_[1] }
sub set_watcher                 { shift->{watcher}              = $_[1] }
sub set_write_watcher           { shift->{write_watcher}        = $_[1] }
sub set_message                 { shift->{message}              = $_[1] }
sub set_is_authenticated        { shift->{is_authenticated}     = $_[1] }
sub set_auth_user               { shift->{auth_user}            = $_[1] }

sub new {
    my $class = shift;
    my ($server, $sock) = @_;

    my $cid = ++$CONNECTION_ID;

    my $self = bless {
        cid                     => $cid,
        sock                    => $sock,
        server                  => $server,
        is_authenticated        => (!$server->get_auth_required),
        auth_user               => "",
        watcher                 => undef,
        write_watcher           => undef,
        message                 => undef,
        client_oids             => {},
        message_format          => $Event::RPC::Server::DEFAULT_MESSAGE_FORMAT,
    }, $class;

    if ( $sock ) {
        $self->log (2,
            "Got new RPC connection. Connection ID is $cid"
        );
        $self->{watcher} = $self->get_server->get_loop->add_io_watcher (
            fh   => $sock,
            poll => 'r',
            cb   => sub { $self->input; 1 },
            desc => "rpc client cid=$cid",
        );
    }

    my $connection_hook = $server->get_connection_hook;
    &$connection_hook($self, "connect") if $connection_hook;

    return $self;
}

sub disconnect {
    my $self = shift;

    $self->get_server->get_loop->del_io_watcher($self->get_watcher);
    $self->get_server->get_loop->del_io_watcher($self->get_write_watcher)
        if $self->get_write_watcher;
    $self->set_watcher(undef);
    $self->set_write_watcher(undef);
    close $self->get_sock;

    my $server = $self->get_server;

    $server->set_clients_connected ( $self->get_server->get_clients_connected - 1 );

    foreach my $oid ( keys %{$self->get_client_oids} ) {
        $server->deregister_object($oid);
    }

    $self->log(2, "Client disconnected");

    my $connection_hook = $server->get_connection_hook;
    &$connection_hook($self, "disconnect") if $connection_hook;

    1;
}

sub get_client_object {
    my $self = shift;
    my ($oid) = @_;

    croak "No object registered with oid '$oid'"
        unless $self->get_client_objects->{$oid};

    return $self->get_client_objects->{$oid};
}

sub log {
    my $self = shift;

    my ($level, $msg);
    if ( @_ == 2 ) {
        ($level, $msg) = @_;
    } else {
        ($msg) = @_;
        $level = 1;
    }

    $msg = "cid=".$self->get_cid.": $msg";

    return $self->get_server->log ($level, $msg);
}

sub input {
    my $self = shift;
    my ($e) = @_;

    my $server  = $self->get_server;
    my $message = $self->get_message;

    if ( not $message ) {
        $message = $self->get_message_format->new ($self->get_sock);
        $self->set_message($message);
    }

    my $request = eval { $message->read } || '';
    my $error = $@;

    return if $request eq '' && $error eq '';

    $self->set_message(undef);

    return $self->disconnect
        if $request eq "DISCONNECT\n" or
           $error =~ /DISCONNECTED/;

    $server->set_active_connection($self);

    my ($cmd, $rc);
    $cmd = $request->{cmd} if not $error;

    $self->log(4, "RPC command: $cmd");

    if ( $error ) {
        $self->log ("Unexpected error on incoming RPC call: $@");
        $rc = {
            ok  => 0,
            msg => "Unexpected error on incoming RPC call: $@",
        };
    }
    elsif ( $cmd eq 'neg_formats_avail') {
        $rc = {
            ok       => 1,
            msg      => join(",", @{$self->get_server->get_message_formats})
        };
    }
    elsif ( $cmd eq 'neg_format_set') {
        $rc = $self->client_requests_message_format($request->{msg});
    }
    elsif ( $cmd eq 'version' ) {
        #-- Probably we have fallen back to Storable because an old
        #-- client has connected. so we change the negotiation
        #-- message handler to the fallback handler for further
        #-- communication on this connection.
        $self->set_message_format(ref $message);

        $rc = {
            ok       => 1,
            version  => $Event::RPC::VERSION,
            protocol => $Event::RPC::PROTOCOL,
        };
    }
    elsif ( $cmd eq 'auth' ) {
        $rc = $self->authorize_user ($request);
    }
    elsif ( $server->get_auth_required && !$self->get_is_authenticated ) {
        $rc = {
            ok  => 0,
            msg => "Authorization required",                        
        };
    }
    elsif ( $cmd eq 'new' ) {
        $rc = $self->create_new_object ($request);
    }
    elsif ( $cmd eq 'exec' ) {
        $rc = $self->execute_object_method ($request);
    }
    elsif ( $cmd eq 'classes_list' ) {
        $rc = $self->get_classes_list ($request);
    }
    elsif ( $cmd eq 'class_info' ) {
        $rc = $self->get_class_info ($request);
    }
    elsif ( $cmd eq 'class_info_all' ) {
        $rc = $self->get_class_info_all ($request);
    }
    elsif ( $cmd eq 'client_destroy' ) {
        $rc = $self->object_destroyed_on_client ($request);
    }
    else {
        $self->log ("Unknown request command '$cmd'");
        $rc = {
            ok  => 0,
            msg => "Unknown request command '$cmd'",
        };
    }

    $server->set_active_connection(undef);

    $message->set_data($rc);

    my $watcher = $self->get_server->get_loop->add_io_watcher (
        fh      => $self->get_sock,
        poll    => 'w',
        cb      => sub {
            if ( $message->write ) {
                $self->get_server->get_loop->del_io_watcher($self->get_write_watcher)
                    if $self->get_write_watcher;
                $self->set_write_watcher();
            }
            1;
        },
    );

    $self->set_write_watcher($watcher);

    1;
}

sub client_requests_message_format {
    my $self = shift;
    my ($client_format) = @_;

    foreach my $format ( @{$self->get_server->get_message_formats} ) {
        if ( $client_format eq $format ) {
            $self->set_message_format(
                Event::RPC::Message::Negotiate->known_message_formats
                                              ->{$client_format}
            );

            eval "use ".$self->get_message_format;
            return { ok => 0, msg => "Server rejected format '$client_format': $@" }
                if $@;

            return { ok => 1 };
        }
    }

    return { ok => 0, msg => "Server rejected format '$client_format'" };
}

sub authorize_user {
    my $self = shift;
    my ($request) = @_;

    my $user = $request->{user};
    my $pass = $request->{pass};

    my $auth_module = $self->get_server->get_auth_module;

    return {
        ok  => 1,
        msg => "Not authorization required",
    } unless $auth_module;

    my $ok = $auth_module->check_credentials ($user, $pass);

    if ( $ok ) {
        $self->set_auth_user($user);
        $self->set_is_authenticated(1);
        $self->log("User '$user' successfully authorized");
        return {
            ok  => 1,
            msg => "Credentials Ok",
        };
    }
    else {
        $self->log("Illegal credentials for user '$user'");
        return {
            ok  => 0,
            msg => "Illegal credentials",
        };
    }
}

sub create_new_object {
    my $self = shift;
    my ($request) = @_;

    # Let's create a new object
    my $class_method = $request->{method};
    my $class = $class_method;
    $class =~ s/::[^:]+$//;
    $class_method =~ s/^.*:://;

    # check if access to this class/method is allowed
    if ( not defined $self->get_classes->{$class}->{$class_method} or
         $self->get_classes->{$class}->{$class_method} ne '_constructor' ) {
            $self->log ("Illegal constructor access to $class->$class_method");
            return {
                ok  => 0,
                msg => "Illegal constructor access to $class->$class_method"
            };

    }

    # ok, load class and execute the method
    my $object = eval {
        # load the class if not done yet
        $self->load_class($class) if $self->get_server->get_load_modules;

        # resolve object params
        $self->resolve_object_params ($request->{params});

        $class->$class_method (@{$request->{params}})
    };

    # report error
    if ( $@ ) {
        $self->log ("Error: can't create object ".
                    "($class->$class_method): $@");
        return {
            ok  => 0,
            msg => $@,
        };
    }

    # register object
    $self->get_server->register_object ($object, $class);
    $self->get_client_oids->{"$object"} = 1;

    # log and return
    $self->log (5,
        "Created new object $class->$class_method with oid '$object'",
    );

    return {
        ok  => 1,
        oid => "$object",
    };
}

sub load_class {
    my $self = shift;
    my ($class) = @_;

    my $mtime;
    my $load_class_info = $self->get_loaded_classes->{$class};

    if ( not $load_class_info or
         ( $self->get_server->get_auto_reload_modules &&
           ( $mtime = (stat($load_class_info->{filename}))[9])
              > $load_class_info->{mtime} ) )
    {
        if ( not $load_class_info->{filename} ) {
            my $filename;
            my $rel_filename = $class;
            $rel_filename =~ s!::!/!g;
            $rel_filename .= ".pm";

            foreach my $dir ( @INC ) {
                $filename = "$dir/$rel_filename", last
                        if -f "$dir/$rel_filename";
            }

            croak "File for class '$class' not found\n"
                if not $filename;

            $load_class_info->{filename} = $filename;
            $load_class_info->{mtime} = 0;
        }

        $mtime ||= 0;

        $self->log (3, "Class '$class' ($load_class_info->{filename}) changed on disk. Reloading...")
            if $mtime > $load_class_info->{mtime};

        do $load_class_info->{filename};

        if ( $@ ) {
            $self->log ("Can't load class '$class': $@");
            $load_class_info->{mtime} = 0;
            die "Can't load class $class: $@";
        }
        else {
            $self->log (3, "Class '$class' successfully loaded");
            $load_class_info->{mtime} = time;
        }
    }

    $self->log (5, "filename=".$load_class_info->{filename}.
                ", mtime=".$load_class_info->{mtime} );

    $self->get_loaded_classes->{$class} ||= $load_class_info;

    1;
}

sub execute_object_method {
    my $self = shift;
    my ($request) = @_;

    # Method call of an existent object
    my $oid = $request->{oid};
    my $object_entry = $self->get_objects->{$oid};
    my $method = $request->{method};

    if ( not defined $object_entry ) {
        # object does not exist
        $self->log ("Illegal access to unknown object with oid=$oid");
        return {
            ok  => 0,
            msg => "Illegal access to unknown object with oid=$oid"
        };
    }

    my $class = $object_entry->{class};
    if ( not defined $self->get_classes->{$class} or
         not defined $self->get_classes->{$class}->{$method} )
    {
        # illegal access to this method
        $self->log ("Illegal access to $class->$method");
        return {
            ok  => 0,
            msg => "Illegal access to $class->$method"
        };
    }

    my $return_type = $self->get_classes->{$class}->{$method};

    # ok, try loading class and executing the method
    my @rc = eval {
        # (re)load the class if not done yet
        $self->load_class($class) if $self->get_server->get_load_modules;

        # resolve object params
        $self->resolve_object_params ($request->{params});

        # exeute method
        $object_entry->{object}->$method (@{$request->{params}})
    };

    # report error
    if ( $@ ) {
        $self->log ("Error: can't call '$method' of object ".
                    "with oid=$oid: $@");
        return {
            ok  => 0,
            msg => "$@",
        };
    }

    # log
    $self->log (4, "Called method '$method' of object ".
                   "with oid=$oid");

    if ( $return_type eq '_object' ) {
        # check if objects are returned by this method
        # and register them in our internal object table
        # (if not already done yet)
        my $key;
        foreach my $rc ( @rc ) {
            if ( ref ($rc) and ref ($rc) !~ /ARRAY|HASH|SCALAR/ ) {
                # returns a single object
                $self->log (4, "Method returns object: $rc");
                $key = "$rc";
                $self->get_client_oids->{$key} = 1;
                $self->get_server->register_object($rc, ref $rc);
                $rc = $key;

            }
            elsif ( ref $rc eq 'ARRAY' ) {
                # possibly returns a list of objects
                # make a copy, otherwise the original object references
                # will be overwritten
                my @val = @{$rc};
                $rc = \@val;
                foreach my $val ( @val ) {
                    if ( ref ($val) and ref ($val) !~ /ARRAY|HASH|SCALAR/ ) {
                        $self->log (4, "Method returns object lref: $val");
                        $key = "$val";
                        $self->get_client_oids->{$key} = 1;
                        $self->get_server->register_object($val, ref $val);
                        $val = $key;
                    }
                }
            }
            elsif ( ref $rc eq 'HASH' ) {
                # possibly returns a hash of objects
                # make a copy, otherwise the original object references
                # will be overwritten
                my %val = %{$rc};
                $rc = \%val;
                foreach my $val ( values %val ) {
                    if ( ref ($val) and ref ($val) !~ /ARRAY|HASH|SCALAR/ ) {
                        $self->log (4, "Method returns object href: $val");
                        $key = "$val";
                        $self->get_client_oids->{$key} = 1;
                        $self->get_server->register_object($val, ref $val);
                        $val = $key;
                    }
                }
            }
        }
    }

    # return rc
    return {
        ok => 1,
        rc => \@rc,
    };
}

sub object_destroyed_on_client {
    my $self = shift;
    my ($request) = @_;

    $self->log(5, "Object with oid=$request->{oid} destroyed on client");

    delete $self->get_client_oids->{$request->{oid}};
    $self->get_server->deregister_object($request->{oid});

    return {
        ok => 1
    };
}

sub get_classes_list {
    my $self = shift;
    my ($request) = @_;

    my @classes = keys %{$self->get_classes};

    return {
        ok      => 1,
        classes => \@classes,
    }
}

sub get_class_info {
    my $self = shift;
    my ($request) = @_;

    my $class = $request->{class};

    if ( not defined $self->get_classes->{$class} ) {
        $self->log ("Unknown class '$class'");
        return {
            ok  => 0,
            msg => "Unknown class '$class'"
        };
    }

    $self->log (4, "Class info for '$class' requested");

    return {
        ok           => 1,
        methods      => $self->get_classes->{$class},
    };
}

sub get_class_info_all {
    my $self = shift;
    my ($request) = @_;

    return {
        ok             => 1,
        class_info_all => $self->get_classes,
    }
}

sub resolve_object_params {
    my $self = shift;
    my ($params) = @_;

    my $key;
    foreach my $par ( @{$params} ) {
        if ( defined $self->get_classes->{ref($par)} ) {
            $key = ${$par};
            $key = "$key";
            croak "unknown object with key '$key'"
                    if not defined $self->get_objects->{$key};
            $par = $self->get_objects->{$key}->{object};
        }
    }

    1;
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Connection - Represents a RPC connection

=head1 SYNOPSIS

Note: you never create instances of this class in your own code,
it's only used internally by Event::RPC::Server. But you may request
connection objects using the B<connection_hook> of Event::RPC::Server
and then having some read access on them.

  my $connection = Event::RPC::Server::Connection->new (
      $rpc_server, $client_socket
  );

As well you can get the currently active connection from your
Event::RPC::Server object:

  my $server     = Event::RPC::Server->instance;
  my $connection = $server->get_active_connection;

=head1 DESCRIPTION

Objects of this class represents a connection from an Event::RPC::Client
to an Event::RPC::Server instance. They live inside the server and
the whole Client/Server protocol is implemented here.

=head1 READ ONLY ATTRIBUTES

The following attributes may be read using the corresponding
get_ATTRIBUTE accessors:

=over 4

=item B<cid>

The connection ID of this connection. A number which is unique
for this server instance.

=item B<server>

The Event::RPC::Server instance this connection belongs to.

=item B<is_authenticated>

This boolean value reflects whether the connection is authenticated
resp. whether the client passed correct credentials.

=item B<auth_user>

This is the name of the user who was authenticated successfully for
this connection.

=item B<client_oids>

This is a hash reference of object id's which are in use by the client of
this connection. Keys are the object ids, value is always 1.
You can get the corresponding objects by using the

  $connection->get_client_object($oid)

method.

Don't change anything in this hash, in particular don't delete or add
entries. Event::RPC does all the necessary garbage collection transparently,
no need to mess with that.

=back

=head1 AUTHORS

  Jörn Reder <joern AT zyn.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
