#!/usr/bin/perl
# Example HTTP::Server::Simple::CGI JSON-RPC Server.
# Enable following to test on installation area.
use lib ('..');

use strict;
use warnings;
# Test Classes to host on server.
use SimpleMath; # Contains package Math
use LongSearch; # Async Search
use SoundIt; # Async Search
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
{
  package MyJRPC;
  use HTTP::Server::Simple::CGI;
  use base 'HTTP::Server::Simple::CGI';
  # TODO: Check access to packages.
  our $pkgacl = {'SimpleMath' => 1, 'LongSearch' => 1,};
  use JRPC::CGI;
  # Reuse handle_simple_server_cgi, assign as local alias.
  *handle_request = \&JRPC::CGI::handle_simple_server_cgi;
};
# Server Instantiation
my $port = $ENV{'HTTP_SIMPLE_PORT'} || 8080;
#MyJRPC->new($port)->run();$pid = $$;
my $pid = MyJRPC->new($port)->background();

print "Use 'kill $pid' to stop server (on port $port).\n";



#my $url = "http://localhost/Math";
#my $body = `cat ../t/test_add.json`;
use Data::Dumper;
use JRPC::Client;
my $url = "http://localhost:$port/Math";
# 
#testaddition($url, 'test' => 0);
#print(Dumper($res));
my $killnow = 0;
if ($killnow) {kill(9, $pid);}
# man 7 signal, perldoc perlipc
# INT = Ctrl+C
else {$SIG{'INT'} = sub { kill(9, $pid); };}
sub testaddition {
  my ($url, %c) = @_;
  if ($c{'test'}) {eval("use Test::More;");}
  my $cl = JRPC::Client->new();
  #print(Dumper($cl));
  my $req = $cl->new_request($url, ); # 'debug' => 1
  for (0..10) {
    #my $req = $cl->new_request($url, ); # 'debug' => 1
    #my $res; # {'value' => 1}
    my $res = eval { $req->call('add', [1,2,3], ); };  # 'debug' => 1
    if ($@ || !$res) {die("Call Error: $@ (res=$res)");}
    if ($res) {print("Got ($res): '".$res->content()."'\n");}
    #print(Dumper($res));
    my $sum = 0;
    map({$sum += $_;} @{[1,2,3]});
    my $sumof = join(',', @{[1,2,3]});
    my $jresp = $res->parsed_content();
    my $sumres = $jresp->{'result'}->{'res'};
    if ($c{'test'}) {ok($sum == $sumres, "Sum of $sumof = $sumres");}
    else { print(Dumper($jresp)); }
  }
}

