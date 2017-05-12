#!/usr/bin/perl

#ABSTRACT: Example Demonstrating Facebook::Graph::Cmdline life cycle

# show_group_events.pl:
#  Demonstrates Facebook::Graph::Cmdline life cycle
#
#  Initializes Facebook::Graph::Cmdline from a yaml
#  configfile(facebook.yml), creates and saves an
#  access token, requests information about a specific
#  group's events.

use warnings;
use strict;
use v5.10.0;

use Data::Dumper;
use Facebook::Graph::Cmdline;
my $fb = Facebook::Graph::Cmdline->new_with_config(
    configfile => 'facebook.yml' );

$fb->save_access_token();

my $lapm_group_id = '119158178096277';
my $events = $fb->fetch("$lapm_group_id/events");
#print Dumper $events;
say "Next five events:";
foreach my $event ( @{$events->{data}}[0..4])
{
    say join("\t", $event->{name}, $event->{start_time});
}
