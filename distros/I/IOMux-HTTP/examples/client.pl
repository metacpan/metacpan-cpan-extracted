#!/usr/bin/env perl
# This script demonstrates an HTTP client, to be used with the
# daemon.pl in this same directory.
#
# You may run the test with
#   ./server.pl                # to start the server
#   ./client.pl                # this script
#   kill $(cat server.pl.pid)  # stop server
# Don't forget to look in /var/log/messages!
#
# The server will also work when the client is not multiplexed. The
# multiplexing client will also works when the server is not multiplexed.

use warnings;
use strict;

use Log::Report;

# Any IOMux multiplexer implementation (choice independent from
# the choice in the server.
use IOMux::Select;
#use IOMux::Poll;

use IOMux::HTTP::Client;

use Getopt::Long   qw/GetOptions :config no_ignore_case bundling/;
use File::Basename qw/basename/;
use HTTP::Status   qw/HTTP_OK/;

sub start_requesting($);

#
## get command-line options
#

my $mode     = 0;     # increase output

my %net_opts =
  ( host       => 'localhost:5422'
  , port       => undef
  );

GetOptions
   'host|h=s'       => \$net_opts{host}
 , 'port|p=s'       => \$net_opts{port}
 , 'v+'             => \$mode  # -v -vv -vvv
    or exit 1;

unless(defined $net_opts{port})
{   my $port = $net_opts{port} = $1
        if $net_opts{host} =~ s/\:([0-9]+)$//;
    defined $port or error "no port specified";
}

# From now on, all errors and warnings are also sent to syslog,
# provided by Log::Report. Output still also to the screen.
dispatcher SYSLOG => 'syslog', accept => 'INFO-'
  , identity => 'http-c', facility => 'local0';

dispatcher mode => $mode, 'ALL' if $mode;

my $addr   = "$net_opts{host}:$net_opts{port}";
my $client = IOMux::HTTP::Client->new
  ( # Configures the server socket
    PeerAddr => $addr
  , Proto     => 'tcp'
  );

# Start any multiplexer.
my $mux    = IOMux::Select->new;
#my $mux    = IOMux::Poll->new;
$mux->add($client);

start_requesting($client);

$mux->loop;

# All handled
exit 0;

########### Webclient logic

use Data::Dumper;
sub start_requesting($)
{   my $client = shift;
    my $session = {aap => 1};
    my $req1 = HTTP::Request->new(GET => '/any/uri/step1');
    $client->sendRequest($req1, \&step2, $session);
}

sub step2
{   my ($client, $req1, $status, $resp1, $session) = @_;
    print "cl status1 = $status; uri =".$req1->uri."\n";
    for my $c (2..9)
    {   my $reqc = HTTP::Request->new(GET => "req-step$c");
        $client->sendRequest($reqc, \&step3, $session);
    }
}

sub step3
{   my ($client, $reqc, $status, $resp, $session) = @_;
    print "cl status = $status, uri=".$reqc->uri." resp=".$resp->content."\n";
    ++$session->{received} ==8 or return;

    print "all received";
    $client->close;
}

1;
