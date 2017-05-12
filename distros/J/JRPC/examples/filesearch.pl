#!/usr/bin/perl
# Do a asyncronous remote file search.

=SYNOPSIS

    # Run Server
    export HTTP_SIMPLE_PORT=8090
    ./simpleserver.pl
    # Run (this) Client
    ./filesearch.pl

=cut
use Data::Dumper;
use JRPC::Client;
use threads;

my $servport = $ENV{'HTTP_SIMPLE_PORT'} || 8090;
my $cbport = $servport + 10;
if ($ENV{'JRPC_DEBUG'}) {$JRPC::Client::Request::debug = 1;}
my $client = JRPC::Client->new();
my $meth = 'LongSearch.searchpath';
my $params = {'path' => "/etc", 'cburl' => "http://localhost:$cbport/"};
###### Main flow ########
$req = $client->new_request("http://localhost:$servport/");
my $resp = $req->call($meth, $params);
if (my $err = $resp->error()) { die($err->{'message'}); }
my $res = $resp->result();
#print("Local time in CET is: $res->{'timeiso'}\n");
print("Sync result: ".Dumper($res));

sub createcbserver {
   my ($foo) = @_;
   print("Spawning Callback Server thread on $cbport. Waiting ...\n");
   CBServer->new($cbport)->run();
}

my $thr = threads->create('createcbserver', ); # 'argument'
# Block and wait response
$thr->join();
# Example fault duplication (this gets duplicated)
# {"jsonrpc":"2.0","error":{"code":500,"message":"Error in processing JSON-RPC method 'LongSearch.searchpath' (-32603): Not forked for async processing at LongSearch.pm line 20, <DATA> line 16.\n"},"id":2}

{
  package CBServer;
  use HTTP::Server::Simple::CGI;
  use base 'HTTP::Server::Simple::CGI';
  use JRPC::CGI;
  # Reuse handle_simple_server_cgi, assign as local alias.
  #*handle_request = \&JRPC::CGI::handle_simple_server_cgi;
  sub handle_request {
     my ($self, $cgi) = @_;
     my $d = $cgi->param('POSTDATA');
     my $len = length($d);
     print("{}"); # Dummy from JRPC ?
     # Note: Anything to STDOUT will go back to Client. MUST be JSON !
     print(STDERR "Got Request as async response to original query ($len B of JSON):\n$d"); # .$d."\n\n"
     my $fileinfo = JSON::XS::decode_json($d);
     my $files = $fileinfo->{'params'}->{'files'};
     print(STDERR map({" - $_\n"} @$files));
     #$thr->kill();
     threads->exit(); 
  }
};

