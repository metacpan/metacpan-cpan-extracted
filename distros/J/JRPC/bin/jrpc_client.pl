#!/usr/bin/perl
use Data::Dumper;
use JRPC::Client;
use JSON::XS;
use Getopt::Long;

#use threads;
use strict;
use warnings;

=head1 NAME

jrpc_client.pl - Generic JSON-RPC Client for JRPC toolkit

=head1 SYNOPSIS

./jrpc_client.pl -parafile examples/say.json -method 'SoundIt.say' \
   -url "http://servhost:8080/"

=head DESCRIPTION

Parameters:

=over 4

=item * url - Service URL to send JSON-RPC request to

=item * method - JSON-RPC Method  (e.g 'Pkg.meth' or just 'meth')

=item * parafile - JSON file with parameters for JSON-RPC "params" section

=back

=cut

my $defport = 8090;
# TODO: Add async waiting as an option here
# async=... - name of sub/file/method ???
my %para = ('url' => "http://localhost:$defport/",
   'parafile' => '', 'method' => '', 'async' => '');
my @pspec = ('url=s', 'parafile=s', 'method=s', "async=s");
GetOptions (\%para, @pspec);
if (!$para{'url'}) {die("Need URL");}
#if (!$para{'parafile'}) {die("Need JSON-RPC Parameter file ('parafile')");}
if (!$para{'method'}) {die("Need 'method' (In valid format 'mymeth' or 'Pkg.mymeth')");}

# Process parameters. Allow none
my $jparams = undef;
if ($para{'parafile'}) {
  if (! -f $para{'parafile'}) {die("Param file '$para{'parafile'} does not exist !");}
  $jparams = decode_json(`cat $para{'parafile'}`);
}

#my $servport = $ENV{'HTTP_SIMPLE_PORT'} || 8090;
#my $cbport = $servport + 10;
if ($ENV{'JRPC_DEBUG'}) {$JRPC::Client::Request::debug = 1;}
my $client = JRPC::Client->new();
#my $meth = 'LongSearch.searchpath';
#my $params = {'path' => "/etc", 'cburl' => "http://localhost:$cbport/"};
###### Main flow ########
my $req = $client->new_request($para{'url'});
my $resp = $req->call($para{'method'}, $jparams);
if (my $err = $resp->error()) { die("JSON-RPC Error: $err->{'message'} ($err->{'code'})"); }
my $res = $resp->result();
#print("Local time in CET is: $res->{'timeiso'}\n");
print("Sync result: ".Dumper($res));
# TODO: If async processing takes place in server end, wait here...
if ($para{'async'}) {
   #eval("use ");
   # Spawn waiting server
}
