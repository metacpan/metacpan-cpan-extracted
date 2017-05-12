use strict;
use warnings;
use Test::More;
use Message::Passing::Output::ZeroMQ;

my $output = Message::Passing::Output::ZeroMQ->new();

my $version = $output->zmq_major_version;
like $version, qr/^[234]$/, "ZMQ is a sane major version: $version";

done_testing;

