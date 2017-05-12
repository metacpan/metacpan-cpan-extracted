#!/usr/bin/perl

#=======================================================================
# Record.pm / IPTables::Log::Set::Record
# $Id: Record.pm 21 2010-12-17 21:07:37Z andys $
# $HeadURL: https://daedalus.dmz.dn7.org.uk/svn/IPTables-Log/trunk/IPTables-Log/lib/IPTables/Log/Set/Record.pm $
# (c)2009 Andy Smith <andy.smith@netprojects.org.uk>
#-----------------------------------------------------------------------
#:Description
# This class holds a single IPTables/Netfilter record.
#-----------------------------------------------------------------------
#:Synopsis
# NOTE: This class isn't designed to be created directly.
#
# use IPTables::Log;
# my $l = IPTables::Log->new;
# my $s = $l->create_set;
# my $r = $s->create_record({text => '...IN=eth0 OUT=eth1 MAC=00:...'});
# $r->parse;
#=======================================================================

# The pod (Perl Documentation) for this module is provided inline. For a
# better-formatted version, please run:-
# $ perldoc Record.pm

=head1 NAME

IPTables::Log::Set::Record - Holds a single IPTables/Netfilter log entry.

=head1 SYNOPSIS

Note that this class isn't designed to be created directly. You can create these objects via a C<IPTables::Log::Set> object.

  use IPTables::Log;
  my $l = IPTables::Log->new;
  my $s = $l->create_set;
  my $r = $s->create_record({text => '...IN=eth0 OUT=eth1 MAC=00:...'});
  $r->parse;

=head1 DEPENDENCIES

=over 4

=item * Class::Accessor - for accessor methods

=item * Data::GUID - for GUID generation

=item * NetAddr::IP - for the C<src> and C<dst> methods

=back

=cut

# Set the package name
package IPTables::Log::Set::Record;

use 5.010000;
use strict;
use warnings;

# Use Data::GUID for generating GUIDs
use Data::GUID;
# Use Data::Dumper for debugging. Can be removed for releases.
use Data::Dumper;
# Use NetAddr::IP for IP addresses
use NetAddr::IP;
use NetAddr::IP::Util qw(inet_aton);

# Inherit from Class::Accessor, which saves us quite a bit of time.
use base qw(Class::Accessor);
# Follow best practice
__PACKAGE__->follow_best_practice;
# Make 'text' a read/write accessor method
__PACKAGE__->mk_accessors( qw(text parsed) );
# Make the rest read-only
__PACKAGE__->mk_ro_accessors( qw(log guid date time hostname prefix in out mac src dst proto _spt _dpt spt dpt id len ttl df window syn type code) );

# Set version information
our $VERSION = '0.0005';

=head1 CONSTRUCTORS

=head2 Record->create(I<{text => '...IN=eth0 OUT=eth1 MAC=00:...'}>)

Creates a new C<IPTables::Log::Set::Record> object. You shouldn't call this directly - see the synopsis for an example.

=cut

# Call create instead of new, and the GUID will be generated automatically
sub create
{
	my ($class, $args) = @_;

	my $self = __PACKAGE__->new($args);
	# Generate a GUID for the ID
	my $g = Data::GUID->new;
	$self->{guid} = $g->as_string;
	$self->{no_header} = $args->{'no_header'} ? $args->{'no_header'} : 0;
	$self->{parsed} = 0;

	return $self;
}

# Private function for checking the content of fields
# Not documented in pod format because this is a private function.
sub _process_value
{
	my ($self, $value, $name) = @_;

	# If $value isn't set, set it to "NONE". A blank string will break IPTables::Log::Set->get_by().
	if((!$value) || ($value eq ""))
	{
		$value = "NONE";
	}

	$self->{$name} = $value;
	return 1;
}

# As for _process_value, but if true replaces the value with a 1, otherwise replaces it with a 0
# Not documented in pod format because this is a private function.
sub _process_present
{
	my ($self, $value, $name) = @_;

	if($value)
	{
		$self->{$name} = 1;
	}
	else
	{
		$self->{$name} = 0;
	}
	return 1;
}

=head1 METHODS

=head2 $record->parse

Parses the log message text passed either to the constructor, or via C<set_text>.

=cut

# Parses the log text
sub parse
{
	my ($self, $text) = @_;

	if(!$self->get_text)
	{
		if($text)
		{
			# Set the text attribute to the original log message
			$self->set_text($text);
		}
		else
		{	
			#$self->get_log->error("No log text found?");
			return;
		}
	}
	else
	{
		$text = $self->get_text;
	}

	#$self->get_log->debug_value("Original log message is", 'yellow', $text);

	# First, we pull parts out common to all protocols
	my ($date, $time, $hostname, $prefix, $in, $out, $mac, $src, $dst, $len, $ttl, $id, $df, $proto);
	if($self->{'no_header'} eq 1)
	{
		(undef, $prefix, $in, $out, undef, $mac, $src, $dst, $len, $ttl, $id, $df, $proto)
			= $text =~ /kernel:(\s\[\d+\.\d+\])?\s(\S*)\sIN=(\S*)\sOUT=(\S*)\s(MAC=)?(\S+)?\s*SRC=(\d+\.\d+\.\d+\.\d+|\S+)\sDST=(\d+\.\d+\.\d+\.\d+|\S+)\sLEN=(\d+).+TTL=(\d+).+ID=(\d+)\s(DF)*\s*PROTO=(\S+)/;
	}
	else
	{
		($date, $time, $hostname, undef, $prefix, $in, $out, undef, $mac, $src, $dst, $len, $ttl, $id, $df, $proto)
			= $text =~ /(\w{3}\s\d{1,2})\s{1,2}(\d{2}:\d{2}:\d{2})\s(.+)\skernel:(\s\[\d+\.\d+\])?\s(\S*)\sIN=(\S*)\sOUT=(\S*)\s(MAC=)?(\S+)?\s*SRC=(\d+\.\d+\.\d+\.\d+|\S+)\sDST=(\d+\.\d+\.\d+\.\d+|\S+)\sLEN=(\d+).+TTL=(\d+).+ID=(\d+)\s(DF)*\s*PROTO=(\S+)/;
	}

	# Get the protocol first. Based on this, we know what regex we need next.
	$self->_process_value($proto, 'proto');
	if(!$proto)
	{
		#$self->get_log->error("Cannot determine the protocol for this log message!");
		#$self->get_log->error("The log text is ".$self->get_log->fcolour('yellow', $text));
		return;
	}

	# Process values
	# Date
	$self->_process_value($date, 'date');
	# Time
	$self->_process_value($time, 'time');
	# Hostname
	$self->_process_value($hostname, 'hostname');
	# IPTable logging prefix (as specified by '-j LOG --log-prefix="<prefix>"'
	$self->_process_value($prefix, 'prefix');
	# Ingress interface
	$self->_process_value($in, 'in');
	# Egress interface
	$self->_process_value($out, 'out');
	# MAC address, if applicable
	$self->_process_value($mac, 'mac');
	# Source IP
	$self->_process_value($src, '_src');
	if($self->{_src})
	{
		$self->{_src} = new_from_aton NetAddr::IP::Lite (inet_aton($self->{_src}));
		$self->{src} = $self->{_src}->addr();
	}
	# Destination IP
	$self->_process_value($dst, '_dst');
	if($self->{_dst})
	{
		$self->{_dst} = new_from_aton NetAddr::IP::Lite (inet_aton($self->{_dst}));
		$self->{dst} = $self->{_dst}->addr();
	}
	# Packet length
	$self->_process_value($len, 'len');
	# TTL
	$self->_process_value($ttl, 'ttl');
	# Packet ID
	$self->_process_value($id, 'id');
	# Don't fragment
	$self->_process_present($df, 'df');

	if(($proto eq "TCP") || ($proto eq "UDP"))
	{
		# TCP or UDP packet
		my ($spt, $dpt) = $text =~ /PROTO=$proto\sSPT=(\d+)\sDPT=(\d+)/;

		# Source port
		$self->_process_value($spt, 'spt');
		# Destination port
		$self->_process_value($dpt, 'dpt');

		if($proto eq "TCP")
		{
			# TCP specifics
			my ($window, $syn) = $text =~ /WINDOW=(\d+).*(SYN)/;

			# TCP window size
			$self->_process_value($window, 'window');
			# SYN present?
			$self->_process_present($syn, 'syn');
		}
	}
	elsif($proto eq "ICMP")
	{
		my ($type) = $text =~ /ICMP TYPE=(\d+)\sCODE=(\d+)/;

		# ICMP Type
		$self->_process_value($type, 'type');
		$self->_process_value($type, 'code');
	}

	# Return true if we've gotten this far.
	$self->set_parsed(1);
	return 1;
}

=head2 $record->set_text("...IN=eth0 OUT=eth1 MAC=00:...")

Sets the log message text. Either this must be set, or the text must have been passed to C<create>, otherwise C<parse> will error.

=head1 ACCESSOR METHODS

=head2 get(I<field>)

Returns the value of I<field>. Field can be one of I<guid>, I<date>, I<time>, I<hostname>, I<prefix>, I<in>, I<out>, I<mac>, I<src>, I<dst>, I<proto>, I<spt>, I<dpt>, I<id>, I<len>, I<ttl>, I<df>, I<window>, I<syn>.

=cut

# Get accessor that takes the variable to return as an argument
sub get
{
	my ($self, $value) = @_;

	return $self->{$value};
}

=head2 get_guid

Returns the GUID for the packet.

=head2 get_date

Returns the date portion of the log message.

=head2 get_time

Returns the time portion of the log message.

=head2 get_hostname

rETURns the hostname portion of the log message.

=head2 get_prefix

Returns the iptables/netfilter log prefix for the log message, i.e. the part specified by C<-j LOG --log-prefix='I<LOG PREFIX> '>.

=head2 get_in

Returns the ingress interface, if specified.

=head2 get_out

Returns the egress interface, if specified.

=head2 get_mac

Returns the MAC address, if specified.

=head2 get_src

Returns the source IP address.

=head2 get_dst

Returns the destination IP address.

=head2 get_proto

Returns the protocol.

=head2 get_spt - TCP and UDP packets only.

Returns the source port, if applicable.

=head2 get_dpt - TCP and UDP packets only.

Returns the destination port, if applicable

=head2 get_id

Returns the packet ID.

=head2 get_len

Returns the packet length.

=head2 get_ttl

Returns the packet's TTL (Time To Live).

=head2 get_df

Returns the packet's DF (Don't Fragment) value.

=head2 get_window - TCP and UDP packets only.

Returns the packet's window size.

=head2 get_sync

Returns 1 if the packet is a SYN, otherwise returns 0.

=head2 get_parsed

Returns 1 if the packet has been successfully parsed, otherwise returns 0.

=head1 CAVEATS

It parses log entries. It doesn't do much else, yet.

=head1 BUGS

None that I'm aware of ;-)

=head1 AUTHOR

This module was written by B<Andy Smith> <andy.smith@netprojects.org.uk>.

=head1 COPYRIGHT

$Id: Record.pm 21 2010-12-17 21:07:37Z andys $

(c)2009 Andy Smith (L<http://andys.org.uk/>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1
