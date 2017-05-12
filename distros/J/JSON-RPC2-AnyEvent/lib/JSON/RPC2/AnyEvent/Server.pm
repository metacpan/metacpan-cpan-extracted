package JSON::RPC2::AnyEvent::Server;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.02";

use AnyEvent;
use Carp 'croak';
use Scalar::Util 'reftype';
use Try::Tiny;

use JSON::RPC2::AnyEvent::Constants qw(:all);


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    while ( @_ ) {
        my $method = shift;
        my $spec   = shift;
        if ( (reftype $spec // '') eq 'CODE' ) {
            $self->register($method, $spec);
        } else {
            $self->register($method, $spec, shift);
        }
    }
    $self;
}

sub dispatch {
    my $self = shift;
    my $json = shift;
    my $ret_cv = AE::cv;
    try{
        my $type = _check_format($json);  # die when $json's format is invalid
        my $method = $self->{$json->{method}};
        unless ( $method ) {  # Method not found
            $ret_cv->send(_make_error_response($json->{id}, ERR_METHOD_NOT_FOUND, 'Method not found'));
            return $ret_cv;
        }
        if ( $type eq 'c' ) {  # RPC call
            $method->(AE::cv{
                my $cv = shift;
                try{
                    $ret_cv->send(_make_response($json->{id}, $cv->recv));
                } catch {
                    $ret_cv->send(_make_error_response($json->{id}, ERR_SERVER_ERROR, 'Server error', shift));
                };
            }, $json->{params});
            return $ret_cv;
        } else {  # Notification request (no response)
            $method->(AE::cv, $json->{params});  # pass dummy cv
            return undef;
        }
    } catch {  # Invalid request
        my $err = _make_error_response((reftype $json eq 'HASH' ? $json->{id} : undef), ERR_INVALID_REQUEST, 'Invalid Request', shift);
        $ret_cv->send($err);
        return $ret_cv;
    };
}

sub _check_format {
    # Returns
    #    "c"  : when the value represents rpc call
    #    "n"  : when the value represents notification
    #    croak: when the value is in invalid format
    my $json = shift;
    reftype $json eq 'HASH'                                                                      or croak "JSON-RPC request MUST be an Object (hash)";
    #$json->{jsonrpc} eq "2.0"                                                                   or croak "Unsupported JSON-RPC version";  # This module supports only JSON-RPC 2.0 spec, but here just ignores this member.
    exists $json->{method} && not ref $json->{method}                                            or croak "`method' MUST be a String value";
    if ( exists $json->{params} ) {
        (reftype $json->{params} // '') eq 'ARRAY' || (reftype $json->{params} // '') eq 'HASH'  or croak "`params' MUST be an array or an object";
    } else {
        $json->{params} = [];
    }
    return 'n' unless exists $json->{id};
    not ref $json->{id}                                                                          or croak "`id' MUST be neighter an array nor an object";
    return 'c';
}

sub _make_response {
    my ($id, $result) = @_;
    {
        jsonrpc => '2.0',
        id      => $id,
        result  => $result,
    };
}

sub _make_error_response {
    my ($id, $code, $msg, $data) = @_;
    {
        jsonrpc => '2.0',
        id      => $id,
        error   => {
            code    => $code,
            message => "$msg",
            (defined $data ? (data => $data) : ()),
        },
    };
}


sub register {
    my $self   = shift;
    my ($method, $spec, $code) = @_;
    if ( UNIVERSAL::isa($spec, "CODE") ) {  # spec is omitted.
        $code = $spec;
        $spec = sub{ $_[0] };
    } else {
        $spec = _parse_argspec($spec);
        croak "`$code' is not CODE ref"  unless UNIVERSAL::isa($code, 'CODE');
    }
    $self->{$method} = sub{
        my ($cv, $params) = @_;        
        $code->($cv, $spec->($params), $params);
    };
    $self;
}

sub _parse_argspec {
    my $orig = my $spec = shift;
    if ( $spec =~ s/^\s*\[\s*// ) {  # Wants array
        croak "Invalid argspec. Unmatched '[' in argspec: $orig"  unless $spec =~ s/\s*\]\s*$//;
        my @parts = split /\s*,\s*/, $spec;
        return sub{
            my $params = shift;
            return $params  if UNIVERSAL::isa($params, 'ARRAY');
            # Got a hash! Then, convert it to an array!
            my $args = [];
            push @$args, $params->{$_}  foreach @parts;
            return $args;
        };
    } elsif ( $spec =~ s/\s*\{\s*// ) {  # Wants hash
        croak "Invalid argspec. Unmatched '{' in argspec: $orig"  unless $spec =~ s/\s*\}\s*$//;
        my @parts = split /\s*,\s*/, $spec;
        return sub{
            my $params = shift;
            return $params  if UNIVERSAL::isa($params, 'HASH');
            # Got an array! Then, convert it to a hash!
            my $args = {};
            for ( my $i=0;  $i < @parts;  $i++ ) {
                $args->{$parts[$i]} = $params->[$i];
            }
            return $args;
        };
    } else {
        croak "Invalid argspec. Argspec must be enclosed in [] or {}: $orig";
    }
}



1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent::Server - Yet-another, transport-independent, asynchronous and simple JSON-RPC 2.0 server

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Server;

    my $srv = JSON::RPC2::AnyEvent::Server->new(
        hello => "[family_name, first_name]" => sub{  # This wants an array as its argument.
            my ($cv, $args) = @_;
            my ($family, $given) = @$args;
            do_some_async_task(sub{
                # Done!
                $cv->send("Hello, $given $family!");
            });
        }
    );

    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 1,
        method  => 'hello',
        params  => [qw(Sogoru Kyo Gunner)],
    });
    my $res = $cv->recv;  # { jsonrpc => "2.0", id => 1, result => "Hello, Kyo Sogoru!" }

    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 2,
        method  => 'hello',
        params  => {  # You can pass hash as well!
            first_name  => 'Ryoko',
            family_name => 'Kaminagi',
            position    => 'Wizard'
        }
    });
    my $res = $cv->recv;  # { jsonrpc => "2.0", id => 2, result => "Hello, Ryoko Kaminagi!" }

    # You can add method separately.
    $srv->register(wanthash => '{family_name, first_name}' => sub{
        my ($cv, $args, $as_is) = @_;
        $cv->send({args => $args, as_is => $as_is});
    });

    # So, how is params translated?
    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 3,
        method  => 'wanthash',
        params  => [qw(Sogoru Kyo Gunner)],
    });
    my $res = $cv->recv;
    # {
    #     jsonrpc => "2.0",
    #     id => 3,
    #     result => {
    #         args  => { family_name => 'Sogoru', first_name => "Kyo" },  # translated to a hash
    #         as_is => ['Sogoru', 'Kyo', 'Gunner'],                       # original value
    #     },
    # }

    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        id      => 4,
        method  => 'wanthash',
        params  => {first_name => 'Ryoko', family_name => 'Kaminagi', position => 'Wizard'},
    });
    my $res = $cv->recv;
    # {
    #     jsonrpc => "2.0",
    #     id => 4,
    #     result => {
    #         args  => {first_name => 'Ryoko', family_name => 'Kaminagi', position => 'Wizard'}, # passed as-is
    #         as_is => {first_name => 'Ryoko', family_name => 'Kaminagi', position => 'Wizard'},
    #     },
    # }

    # For Notification Request, just returns undef.
    my $cv = $srv->dispatch({
        jsonrpc => "2.0",
        method  => "hello",
        params  => [qw(Misaki Shizuno)]
    });
    not defined $cv;  # true


=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Server provides asynchronous JSON-RPC 2.0 server implementation. This just provides an abstract
JSON-RPC layer and you need to combine concrete transport protocol to utilize this module. If you are interested in
stream protocol like TCP, refer to L<JSON::RPC2::AnyEvent::Server::Handle>.

=head1 THINK SIMPLE

JSON::RPC2::AnyEvent considers JSON-RPC as simple as possible. For example, L<JSON::RPC2::Server> abstracts JSON-RPC
server as a kind of hash filter. Unlike L<JSON::RPC2::Server> accepts and outputs serialized JSON text,
L<JSON::RPC2::AnyEvent::Server> accepts and outputs Perl hash:

                         +----------+
                         |          |
                Inuput   | JSON-RPC |  Output
      request ---------->|  Server  |----------> response
    (as a hash)          |          |           (as a hash)
                         +----------+

This has nothing to do with serializing Perl data or deserializing JSON text!

See also L<JSON::RPC2::AnyEvent> for more information.


=head1 INTERFACE

=head2 C<CLASS-E<gt>new( @args )> -> JSON::RPC2::AnyEvent::Server

Create new instance of JSON::RPC2::AnyEvent::Server. Arguments are passed to C<register> method.

=head2 C<$server-E<gt>register( $method_name =E<gt> $argspec =E<gt> $callback )> -> C<$self>

Registers a subroutine as a JSON-RPC method of C<$server>.

=over

=item C<$method_name>:Str

=item C<$argspec>:Str (optional)

=item C<$callback>:CODE

=back

=head2 C<$server-E<gt>dispatch( $val )> -> (AnyEvent::Condvar | undef)

Send C<$val> to C<$server> and execute corresponding method.

=over

=item C<$val>

Any value to send, which looks like JSON data.

=back


=head1 SEE ALSO

=over

=item L<JSON::RPC2::AnyEvent>

=item L<JSON::RPC2::AnyEvent::Server::Handle>

=back


=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

