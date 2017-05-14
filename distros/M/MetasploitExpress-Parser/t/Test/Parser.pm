#!/usr/bin/perl
# $Id: Parser.pm 399 2010-07-19 01:33:17Z jabra $
package t::Test::Parser;

use base 't::Test';
use Test::More;
use Data::Dumper;
sub fields : Tests {
    my ($self) = @_;
  
    my $session1 = $self->{parser1}->get_session();

    is ( $session1->time, '2010-07-31 21:08:27 UTC', 'time');
    is ( $session1->user, 'msmith', 'user');
    is ( $session1->project, 'home', 'project');
    
    my @hosts = $self->{parser1}->get_all_hosts();
    
    is (scalar(@hosts), 4,'size');
    my $first = $hosts[0];
    is ( $first->address, '192.168.1.147', 'address');
    is ( $first->address6, 'NULL', 'address6');
    is ( $first->arch, 'NULL', 'arch');
    is ( $first->comm, '', 'comm');
    is ( $first->created_at, '2010-07-08 22:21:57 UTC', 'created_at');
    is ( $first->id, '527', 'id');

    my @services = $self->{parser1}->get_all_services();
    $first = $services[0];
    is ( $first->created_at, '2010-07-08 22:22:02 UTC', 'created_at');
    is ( $first->host_id, '524', 'host_id');
    is ( $first->name, 'dns', 'name');
    is ( $first->port, '53', 'port');
    is ( $first->proto, 'udp', 'proto');
    is ( $first->state, 'open', 'state');
    is ( $first->updated_at, '2010-07-08 22:22:03 UTC', 'updated_at');

    my @reports = $self->{parser1}->get_all_reports();
    $first = $reports[0];
    is ( $first->created_at, '2010-07-09 16:45:39 UTC', 'created_at');
    is ( $first->created_by, 'msmith', 'host_id');
    is ( $first->downloaded_at, '2010-07-09 16:45:51 UTC', 'downloaded_at');
    is ( $first->id, '13', 'id');
    is ( $first->path, './reports_1280610507/home_1278693934.pdf', 'path');
    is ( $first->workspace_id, '47', 'workspace_id');

    my @events = $self->{parser1}->get_all_events();
    $first = $events[0];
    is ( $first->created_at, '2010-07-08 22:21:43 UTC', 'created_at');
    is ( $first->id, '11087', 'id');

    my @tasks = $self->{parser1}->get_all_tasks();
    $first = $tasks[0];
    is ( $first->completed_at, '2010-07-09 14:57:21 UTC', 'completed_at');
    is ( $first->created_at, '2010-07-09 14:57:21 UTC', 'created_at');
    is ( $first->description, 'Discovering', 'description');
    is ( $first->id, '335', 'id');
}
1;
