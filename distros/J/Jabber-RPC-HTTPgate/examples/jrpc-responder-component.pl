#!/usr/bin/perl -w

# jrpc-responder-component.pl
# Jabber-RPC component-based XML-RPC responder

# see jrpc.xml

use strict;
use Jabber::RPC::Server;

my @states = (qw/Alabama Alaska Arizona Arkansas California Colorado Connecticut
	   Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas
	   Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota
	   Mississippi Missouri Montana Nebraska Nevada/, 'New Hampshire',
	   'New Jersey', 'New Mexico', 'New York', 'North Carolina',
	   'North Dakota', qw/Ohio Oklahoma Oregon Pennsylvania/, 'Rhode Island',
	   'South Carolina', 'South Dakota', qw/Tennessee Texas Utah Vermont
	   Virginia Washington/, 'West Virginia', 'Wisconsin', 'Wyoming');

sub getStateName {
    my $state_num = shift;
    print "getStateName\n";
    return $states[$state_num - 1];
}

sub getStateList {
    my $num_list = shift;
    print "getStateList\n";
    my ($state_num, @state_list);
    foreach $state_num (@$num_list) {
      push @state_list, $states[$state_num - 1];
    }

    return join(',', @state_list);
}

sub getStateStruct {
    my $struct = shift;
    print "getStateStruct\n";
    my ($state_num, @state_list);
    foreach $state_num (values %$struct) {
      push @state_list, $states[$state_num - 1];
    }
    return join(',', @state_list);
}


my $server = new Jabber::RPC::Server(

  server    => 'localhost:5702',
  identauth => 'jrpc.localhost:secret',
  connectiontype => 'component',

  methods   => {
    'examples.getStateName'   => \&getStateName,
    'examples.getStateList'   => \&getStateList,
    'examples.getStateStruct' => \&getStateStruct,
  }
);

$server->start;

