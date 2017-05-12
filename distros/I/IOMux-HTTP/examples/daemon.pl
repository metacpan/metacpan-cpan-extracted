#!/usr/bin/env perl
# This script demonstrates an HTTP server.
#
# You may run the test with
#   wget http://localhost:5422/any/url
# or with ./client.pl in this same directory.

use warnings;
use strict;

use Log::Report;
use Any::Daemon;

#use IOMux::Select;
use IOMux::Poll;
use IOMux::HTTP::Server;

use Getopt::Long   qw/GetOptions :config no_ignore_case bundling/;
use File::Basename qw/basename/;
use HTTP::Status   qw/HTTP_OK/;

#
## get command-line options
#

my $mode     = 0;     # increase output

my %os_opts  =
  ( pid_file   => basename($0). '.pid'  # usually in /var/run
  , user       => undef
  , group      => undef
  );

my %run_opts =
  ( background => 1
  , max_childs => 1    # there can only be one multiplexer
  );

my %net_opts =
  ( host       => 'localhost:5422'
  , port       => undef
  );

GetOptions
   'background|bg!' => \$run_opts{background}
 , 'group|g=s'      => \$os_opts{group}
 , 'host|h=s'       => \$net_opts{host}
 , 'pid-file|p=s'   => \$os_opts{pid_file}
 , 'port|p=s'       => \$net_opts{port}
 , 'user|u=s'       => \$os_opts{user}
 , 'v+'             => \$mode  # -v -vv -vvv
    or exit 1;

$run_opts{background} //= 1;

unless(defined $net_opts{port})
{   my $port = $net_opts{port} = $1
        if $net_opts{host} =~ s/\:([0-9]+)$//;
    defined $port or error "no port specified";
}

#
## initialize the daemon activities
#

# From now on, all errors and warnings are also sent to syslog,
# provided by Log::Report. Output still also to the screen.
dispatcher SYSLOG => 'syslog', accept => 'INFO-'
  , identity => 'http-s', facility => 'local0';

dispatcher mode => $mode, 'ALL' if $mode;

my $daemon = Any::Daemon->new(%os_opts);

$daemon->run
  ( child_task => \&run_multiplexer
  , %run_opts
  );

exit 1;   # will never be called

sub run_multiplexer()
{
#   my $mux    = IOMux::Select->new;
    my $mux    = IOMux::Poll->new;

eval {
    # Create one or more listening TCP or UDP sockets.
    my $addr   = "$net_opts{host}:$net_opts{port}";
    my $server = IOMux::HTTP::Server->new
      ( name      => 'http-server'
      , handler   => \&incoming_request

        # Configures the server socket
      , LocalAddr => $addr
      , Listen    => 5
      , Proto     => 'tcp'

      );
   $mux->add($server);

   $mux->loop;
};
info "EVAL: $@" if $@;
   exit 0;
}

########### Webserver logic

sub incoming_request($$)
{   my ($client, $req) = @_;
    # trace "INCOMING=".$req->as_string;
    my $resp = $client->makeResponse
      ( $req, HTTP_OK
      , [ Content_Type => 'text/plain' ]
      , "URI=".$req->uri
      );
    $client->sendResponse($resp, \&step2);
}


sub step2
{   my ($client, $resp1, $status, $req2) = @_;
info "se step2 $status ".$resp1->content." ".$req2->uri;

    incoming_request $client, $req2  # not for me: new thread
        if $status==HTTP_OK;
}

1;
