#!/usr/bin/env perl
use strict;
use warnings;
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

use EV;
use EV::Websockets;
use JSON::PP ();

# A tiny JSON request/response protocol over WebSocket. The server accepts
#   {"cmd":"echo","text":"hi"}        -> {"ok":1,"text":"hi"}
#   anything else / bad JSON          -> {"ok":0,"error":"..."}
#
# Usage: perl eg/json_protocol.pl [port]
# (->utf8 makes encode/decode work on the byte strings send()/on_message use.)

my $port = shift // 8080;
my $json = JSON::PP->new->utf8->canonical;
my $ctx  = EV::Websockets::Context->new;

my $bound = $ctx->listen(
    port       => $port,
    on_message => sub {
        my ($conn, $data) = @_;
        my $req = eval { $json->decode($data) };
        if (!$req || ref $req ne 'HASH') {
            $conn->send($json->encode({ ok => 0, error => 'invalid JSON' }));
            return;
        }
        if (($req->{cmd} // '') eq 'echo') {
            $conn->send($json->encode({ ok => 1, text => $req->{text} }));
        } else {
            $conn->send($json->encode({ ok => 0, error => "unknown cmd: " . ($req->{cmd} // '') }));
        }
    },
    on_error => sub { my ($conn, $err) = @_; warn "error: $err\n" },
);

warn "JSON protocol server on port $bound\n";
EV::run;
