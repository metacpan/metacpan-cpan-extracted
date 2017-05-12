#!/usr/bin/env perl
# This script can be used as template for daemons using IOMux.
# The code is more verbose than needed in the common case.
#
# Purpose: the daemon returns the text it receives.
# You may run the test with
#   ls | netcat localhost 5422 || echo 'not running'

use warnings;
use strict;

use Log::Report;
use Any::Daemon;

#use IOMux::Select;
use IOMux::Poll;
use IOMux::Service::TCP;

use Getopt::Long   qw/GetOptions :config no_ignore_case bundling/;
use File::Basename qw/basename/;

#use IO::Socket::SSL; # when SSL is used anywhere

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
  , max_childs => 1   # all done in 1 task
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
  , identity => 'iomux', facility => 'local0';

dispatcher mode => $mode, 'ALL'
    if $mode;

# close output to stderr/die/warn when in background
dispatcher close => 'default'
    if $run_opts{background};

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

    # Create one or more listening TCP or UDP sockets.
    my $addr   = "$net_opts{host}:$net_opts{port}";
    my $server = IOMux::Socket::TCP->new
      ( # Options which start with Caps are for IO::Socket::INET/::SSL
        # you may also pass a prepared socket.
        LocalAddr => $addr
      , Listen    => 5
      , Proto     => 'tcp'
     #, use_ssl   => 1     # for SSL socket

        # more options
      , name      => 'echo'           # improves error msgs
      , conn_type => 'IOMux::Echo'    # required, see below
      );

   $mux->add($server);
   $mux->loop(\&heartbeat);

   exit 0;
}

##### HELPERS

# When added to the loop, it will be called each time the select has
# received something.
sub heartbeat($$$)
{   my ($mux, $numready, $timeleft) = @_;
#   info "*$numready $timeleft\n";
}

##### PROTOCOL HANDLER
# Simple echo service which puts back all data it received.
# Usually in a seperate file.

package IOMux::Echo;
use base 'IOMux::Net::TCP';

use warnings;
use strict;

sub mux_input($)
{   my ($self, $input) = @_;
    $self->write($input);     # write expects SCALAR
    $$input = '';             # all bytes processed
}

1;
