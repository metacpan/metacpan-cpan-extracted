#!/usr/bin/env perl
use strict;
use warnings;

## Need GD::Graph3d for this.
##  (Which happens to throw a bad test on every machine I've tried,
##  but always runs perfectly anyway, so I haven't cared enough to look 
##  any deeper at it.)

## Simplistic cron-able example of json-server usage.
##
## Super-cheap, produces grappy graphs.
## (They're not useful until you have an actual data set, either)
## Really just meant as an example of how to use the server.
##
## Here's a 1-hr crontab entry (on the :30):
##  30 * * * * /path/to/chart_users_cron.pl
##
## When run, grab the network users and channels count.
## Store them and output a graph somewhere.
## No output unless there's an error.

## Config me:
#my $json_server = 'http://blackcobalt.net:8700';
#my $users_file  = '/tmp/my_users.db';
#my $chart       = '/tmp/my_chart.png';
#my $network     = 'CobaltIRC';
## How many runs to store.
my $keep_runs    = 64;

die "Edit me and specify some paths!\n"
  unless $json_server and $users_file and $chart;

use GD::Graph::lines3d;

use LWP::UserAgent;

use JSON::XS;
use Compress::Zlib qw/memGunzip/;

use Time::Piece;

my $graphset;
## We happen to have JSON::XS handy ...
if (-e $users_file) {
  open my $fh, '<', $users_file
    or die $!;
  my $json;
  { local $/; $json = <$fh> }
  close($fh);
  $graphset = decode_json($json);
} else {
  $graphset = [
    [ ],  ## time
    [ ],  ## users count
  ];
}

my $ua = LWP::UserAgent->new();

my $retried = 0;
FETCH: {
  ## GET /network/$network in GZIP
  my $response = $ua->get("$json_server/network/$network?gzip");

  ## You'll get a HTTP::Response object.
  if ($response->is_success) {
    my $zipped = $response->content;

    ## Should've gotten gzipped JSON back.
    die "Unknown content-type: ".$response->content_type
      unless $response->content_type eq 'application/x-gzip';
    my $json    = memGunzip($zipped);
    my $netinfo = decode_json($json);
    
    my $user_count = $netinfo->{GlobalUsers} // 0;
    my $t = gmtime->hms;
    my $time = join ':', (split /:/, $t)[0,1];
  
    push(@{ $graphset->[0] }, $time);
    push(@{ $graphset->[1] }, $user_count);
    
    if (@{ $graphset->[0] } > $keep_runs) {
      shift @{ $graphset->[0] };
      shift @{ $graphset->[1] };
    }

    ## Save our new data for later.    
    my $graphset_json = encode_json($graphset);
    open my $fh, '>', $users_file
      or die $!;
    print $fh $graphset_json;
    close $fh;

  } else {
    
    ## If this is a 404, status line from server tells us why.
    if ($response->code == 404) {
      my $line = $response->content;
      
      if ($line =~ /^NO_SUCH/) {
        ## Server doesn't know this network.
        warn "Server appears not to know network $network\n";
        die "Server said: $line\n";
      } elsif ($line =~ /^PENDING/) {
        if ($retried) {
          die "Network marked PENDING twice in a row, giving up.\n"
        } else {
          ++$retried;
          redo FETCH
        }
      }
      
    } else {
      ## HTTP failed and not a 404. We don't know what happened.
      die "HTTP failure: $response->status_line\n"
    }
  
  }

} ## FETCH

## Now we should have a new $graphset and can create a new graph.
## The set looks like:
##  [ time, .. ],
##  [ count, .. ],

## This is braindead:
my $user_set = $graphset->[1];
my $max = 100;
my $min = 50;
use POSIX ();
for (@$user_set) {
  $max = POSIX::ceil($_ /25) * 25 + 25 if $_ > $max;
  $min = POSIX::floor($_ /25) * 25 if $_ < $min;
}

## GD::Graph does a great many things.
##  ... most of them I haven't actually looked at myself.
## See:  perldoc GD::Graph
## This should be enough to start with:

my $graph = GD::Graph::lines3d->new(600, 300);
$graph->set(
  x_label => 'Trawl Time',
  x_label_position => "1/2",
  x_label_skip => 7,
  y_label => 'Network Users',
  title   => "Users",
  y_min_value   => $min,
  y_max_value   => $max,
  y_tick_number => 10,
) or die $graph->error;

my $gd = $graph->plot($graphset)
  or die $graph->error;

open my $imgfh, '>', $chart
  or die "dest image open failed: $!";
binmode $imgfh;
print $imgfh $gd->png;
close $imgfh;
