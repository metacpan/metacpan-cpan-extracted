package MessagePack::RPC::HTTP::Client;
use 5.008005;
use strict;
use warnings;

use Carp;

use Data::MessagePack;
use Furl;

our $VERSION = "0.02";

my $HEADER = ["Content-Type" => "application/x-msgpack"];

# copy & paste from msgpack-rpc-over-http/lib/msgpack-rpc-over-http.rb
my $REQUEST  = 0;    # [0, msgid, method, param]
my $RESPONSE = 1;    # [1, msgid, error, result]
my $NOTIFY   = 2;    # [2, method, param]

my $NO_METHOD_ERROR = 0x01;
my $ARGUMENT_ERROR  = 0x02;

sub new {
    my ($this, $url, %options) = @_;
    my $self = bless +{
        url => $url,
        http_client => Furl->new(
            agent   => "msgpack-rpc-over-http client (perl $VERSION)",
            timeout => $options{timeout} || 5,
          ),
        seqid => 0,
    }, $this;
    $self;
}

sub call {
    my ($self, $method, @args) = @_;
    $self->send_request($method, \@args);
}

sub send_request { # param: ArrayRef
    my ($self, $method, $param) = @_;
    my $data = $self->create_request_body($method, $param);
    # $furl->post($url :Str, $headers :ArrayRef[Str], $content :Any)
    my $res = $self->{http_client}->post($self->{url}, $HEADER, $data);
    unless ($res->is_success) {
        croak "ServerError: check server log or status";
    }
    my $body = $res->body;
    $self->get_result($body);
}

my $SEQID_MAX = ( 1 << 31 );

sub create_request_body {
    my ($self, $method, $param) = @_;
    my $msgid = ($self->{seqid})++;
    $self->{seqid} = 0 if $self->{seqid} >= $SEQID_MAX;
    Data::MessagePack->pack([$REQUEST, $msgid, $method, $param]);
}

sub get_result {
    my ($self, $body) = @_;
    # type, msgid, err, res
    my ($type, $msgid, $err, $res) = @{ Data::MessagePack->unpack($body) };
    if ($type != $RESPONSE) {
        croak "Unknown message type $type";
    }
    if (not defined($err)) {
        return $res;
    } else {
        croak "RemoteError $err: $res";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

MessagePack::RPC::HTTP::Client - Perl version of msgpack-rpc-over-http (ruby) client.

=head1 SYNOPSIS

    use MessagePack::RPC::HTTP::Client;
    my $client = MessagePack::RPC::HTTP::Client->new("http://remote.server.local/");
    my $result = $client->call("remoteMethodName", "param1", "param2");

=head1 DESCRIPTION

MessagePack::RPC::HTTP::Client is a version of 'msgpack-rpc-over-http' client in Perl.

Current version of this module supports only sync call. Async call and streams are not supported now.

=head1 LICENSE

Copyright (C) TAGOMORI Satoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

TAGOMORI Satoshi E<lt>tagomoris@gmail.comE<gt>

=cut

