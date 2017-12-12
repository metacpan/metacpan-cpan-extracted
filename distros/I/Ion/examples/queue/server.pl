#!perl

use common::sense;
use Ion;

my @queue;
my $re_cmd = qr/^(size|get|put)\s*(.*)$/;

my $server = Service {
  my $line  = shift;
  my ($cmd, $data) = $line =~ $re_cmd;

  if ($cmd eq 'get') {
    return shift @queue || 'empty';
  }
  elsif ($cmd eq 'put') {
    push @queue, $data;
    return 'ok';
  }
  elsif ($cmd eq 'size') {
    return scalar @queue . ' items';
  }
} 4242, '127.0.0.1';

printf "Queue started on %s:%d\n", $server->host, $server->port;

$server->join;
