#!perl

use common::sense;

use Ion;
use Coro;
use Coro::ProcessPool;
use Data::Dump::Streamer;
use MIME::Base64 qw(encode_base64 decode_base64);

my $pool   = Coro::ProcessPool->new(max_procs => 4);
my $server = Listen 4242;

$server
  << sub{ decode_base64($_[0]) }
  << sub{ my $msg = eval $_[0]; $@ && die $@; $msg };

$server
  >> sub{ Dump($_[0])->Purity(1)->Declare(1)->Indent(0)->Out }
  >> sub{ encode_base64($_[0], '') };

$server->start;

async_pool {
  while (my $conn = <$server>) {
    async_pool {
      while (my $msg = <$conn>) {
        $conn->($pool->process(@$msg));
      }
    };
  }
};

$server->join;
