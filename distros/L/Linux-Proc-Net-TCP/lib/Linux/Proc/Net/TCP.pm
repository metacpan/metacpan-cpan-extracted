package Linux::Proc::Net::TCP;

our $VERSION = '0.07';

use strict;
use warnings;

use Carp;
use Scalar::Util;

require Linux::Proc::Net::TCP::Base;
our @ISA = qw(Linux::Proc::Net::TCP::Base);

sub read {
    my $class = shift;
    $class->_read(_proto => 'tcp', @_);
}

sub listeners {
    my $table = shift;
    my @l;
    for (@$table) {
	last unless $_->[5] eq '0A';
	push @l, $_;
    }
    @l;
}

sub listener_ports {
    my $table = shift;
    my @p;
    for (sort { $a <=> $b } map $_->local_port, $table->listeners) {
	push @p, $_ unless (($p[-1] || 0) == $_)
    }
    @p;
}

package Linux::Proc::Net::TCP::Entry;
our @ISA = qw(Linux::Proc::Net::TCP::Base::Entry);

my @st_names = ( undef,
		 qw(ESTABLISHED
		    SYN_SENT
		    SYN_RECV
		    FIN_WAIT1
		    FIN_WAIT2
		    TIME_WAIT
		    CLOSE
		    CLOSE_WAIT
		    LAST_ACK
		    LISTEN
		    CLOSING) );

sub _tcp_st2dual {
    my $st = hex shift;
    my $name = $st_names[$st];
    (defined $name ? Scalar::Util::dualvar($st, $name) : $st);
}

sub st                        { _tcp_st2dual shift->[ 5] }

sub retransmit_timeout        {          shift->[16] }
sub predicted_tick            {          shift->[17] }
sub ack_quick                 {          ( shift->[18] || 0 ) >> 1 }
sub ack_pingpong              {          ( shift->[18] || 0 ) &  1 }
sub sending_congestion_window {          shift->[19] }
sub slow_start_size_threshold {          shift->[20] }
sub _more                     {          shift->[21] }



1;
__END__

=head1 NAME

Linux::Proc::Net::TCP - Parser for Linux /proc/net/tcp and /proc/net/tcp6

=head1 SYNOPSIS

  use Linux::Proc::Net::TCP;
  my $table = Linux::Proc::Net::TCP->read;

  for my $entry (@$table) {
    printf("%s:%d --> %s:%d, %s\n",
           $entry->local_address, $entry->local_port,
           $entry->rem_address, $entry->rem_port,
           $entry->st );
  }

=head1 DESCRIPTION

This module can read and parse the information available from
/proc/net/tcp in Linux systems.

=head1 API

=head2 The table object

=over

=item $table = Linux::Proc::Net::TCP->read

=item $table = Linux::Proc::Net::TCP->read(%opts)

reads C</proc/net/tcp> and C</proc/net/tcp6> and returns an object
representing a table of the connections.

Individual entries in the table can be accessed just dereferencing the
returned object. For instance:

  for my $entry (@$table) {
    # do something with $entry
  }

The table entries are of class C<Linux::Proc::Net::TCP::Entry>
described below.

This method accepts the following optional arguments:

=over 4

=item ip4 => 0

disables parsing of the file /proc/net/tcp containing state
information for TCP over IP4 connections

=item ip6 => 0

disables parsing of the file /proc/net/tcp6 containing state
information for TCP over IP6 connections

=item mnt => $procfs_mount_point

overrides the default mount point for the procfs at C</proc>.

=back

=item $table->listeners

returns a list of the entries that are listeners:

  for my $entry ($table->listeners) {
    printf "listener: %s:%d\n", $entry->local_address, $entry->local_port;
  }

=item $table->listener_ports

returns the list of TCP ports where there are some service listening.

This method can be used to find some unused port:

  my @used_ports = Linux::Proc::Net::TCP->read->listener_ports;
  my %used_port = map { $_ => 1 } @used_ports;
  my $port = $start;
  $port++ while $used_port{$port};

=back

=head2 The entry object

The entries in the table are of class
C<Linux::Proc::Net::TCP::Entry> and implement the following read only
accessors:

   sl local_address local_port rem_address rem_port st tx_queue
   rx_queue timer tm_when retrnsmt uid timeout inode reference_count
   memory_address retransmit_timeout predicted_tick ack_quick
   ack_pingpong sending_congestion_window slow_start_size_threshold
   ip4 ip6

=head1 The /proc/net/tcp documentation

This is the documentation about /proc/net/tcp available from the Linux
kernel source distribution:

 This document describes the interfaces /proc/net/tcp and
 /proc/net/tcp6.  Note that these interfaces are deprecated in favor
 of tcp_diag.

 These /proc interfaces provide information about currently active TCP
 connections, and are implemented by tcp4_seq_show() in
 net/ipv4/tcp_ipv4.c and tcp6_seq_show() in net/ipv6/tcp_ipv6.c,
 respectively.

 It will first list all listening TCP sockets, and next list all
 established TCP connections. A typical entry of /proc/net/tcp would
 look like this (split up into 3 parts because of the length of the
 line):

   46: 010310AC:9C4C 030310AC:1770 01 
   |      |      |      |      |   |--> connection state
   |      |      |      |      |------> remote TCP port number
   |      |      |      |-------------> remote IPv4 address
   |      |      |--------------------> local TCP port number
   |      |---------------------------> local IPv4 address
   |----------------------------------> number of entry

   00000150:00000000 01:00000019 00000000  
      |        |     |     |       |--> number of unrecovered RTO timeouts
      |        |     |     |----------> number of jiffies until timer expires
      |        |     |----------------> timer_active (see below)
      |        |----------------------> receive-queue
      |-------------------------------> transmit-queue

   1000        0 54165785 4 cd1e6040 25 4 27 3 -1
    |          |    |     |    |     |  | |  | |--> slow start size threshold, 
    |          |    |     |    |     |  | |  |      or -1 if the threshold
    |          |    |     |    |     |  | |  |      is >= 0xFFFF
    |          |    |     |    |     |  | |  |----> sending congestion window
    |          |    |     |    |     |  | |-------> (ack.quick<<1)|ack.pingpong
    |          |    |     |    |     |  |---------> Predicted tick of soft clock
    |          |    |     |    |     |              (delayed ACK control data)
    |          |    |     |    |     |------------> retransmit timeout
    |          |    |     |    |------------------> location of socket in memory
    |          |    |     |-----------------------> socket reference count
    |          |    |-----------------------------> inode
    |          |----------------------------------> unanswered 0-window probes
    |---------------------------------------------> uid

 timer_active:
  0  no timer is pending
  1  retransmit-timer is pending
  2  another timer (e.g. delayed ack or keepalive) is pending
  3  this is a socket in TIME_WAIT state. Not all fields will contain 
     data (or even exist)
  4  zero window probe timer is pending


=head1 AUTHOR

Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2012, 2014 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
