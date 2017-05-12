#!/usr/bin/perl

#==============================================================================
# Ham::Fldigi::Client
# v0.002
# (c) 2012 Andy Smith, M0VKG
#==============================================================================
# DESCRIPTION
# This module handles communications with a running fldigi instance
#==============================================================================
# SYNOPSIS
# use Ham::Fldigi;
# my $f = new Ham::Fldigi('LogLevel' => 4,
#													'LogFile' => './debug.log',
#													'LogPrint' => 1,
#													'LogWrite' => 1);
# my $client = $f->client('Hostname' => 'localhost',
#													'Port' => '7362',
#													'Name' => 'default');
# $client->modem("BPSK125");
# $client->send("CQ CQ CQ DE M0VKG M0VKG M0VKG KN");
#==============================================================================

# Perl documentation is provided inline in pod format.
# To view, run:-
# perldoc Client.pm

=head1 NAME

Ham::Fldigi::Client - Perl extension for communicating with Fldigi.

=head1 SYNOPSIS

  use Ham::Fldigi;
  my $f = new Ham::Fldigi;
	my $c = $f->client('Hostname' => 'localhost',
										 'Port' => '7362',
										 'Name' => 'example');

	$c->command('fldigi.version');

=head1 DESCRIPTION

This module is for communicating with individual Fldigi instances.

It uses Fldigi's XMLRPC service, which usually runs on localhost:7362, providing support for it has been compiled in.

=head2 EXPORT

None by default.
=cut

package Ham::Fldigi::Client;

use 5.012004;
use strict;
use warnings;

use Moose;
use Data::GUID;
use RPC::XML::Client;
use Data::Dumper;
use Time::HiRes qw( usleep );
use POE qw( Wheel::Run );
use base qw(Ham::Fldigi::Debug);

has 'hostname' => (is => 'rw');
has 'port' => (is => 'rw');
has 'name' => (is => 'rw');
has 'url' => (is => 'ro');
has 'id' => (is => 'ro');
has '_xmlrpc' => (is => 'ro');
has '_session' => (is => 'ro');
has '_buffer_tx' => (is => 'ro');
has '_buffer_rx' => (is => 'ro');

our $VERSION = '0.002';

=head1 CONSTRUCTORS

=head2 Client->new('Hostname' => I<hostname>, 'Port' => I<port>, 'Name' => I<name>)

Creates a new B<Ham::Fldigi::Client> object with the specified arguments. By default, 'localhost' and '7362' are assumed for I<Hostname> and I<Port> respectively. I<Name> is for use with C<Ham::Fldigi::Shell>, and can be safely left blank.

=cut

sub new {
	
	# Get our name, and set an ID
	my $class = shift;
	my $g = Data::GUID->new;

	# Fill in the class ID and version
	my $self =  {
		'version' => $VERSION,
		'id' => $g->as_string,
	};

	# Bless self
	bless $self, $class;

	$self->debug("Constructor called. Version ".$VERSION.", with ID ".$self->id.".");

	# Grab the passed client details.
	# Assume localhost, 7362 and the GUID for the name if no options passed.
	my (%params) = @_;
	if(defined($params{'Hostname'})) {
		$self->hostname($params{'Hostname'});
	} else {
		$self->hostname("localhost");
	}
	if(defined($params{'Port'})) {
		$self->port($params{'Port'});
	} else {
		$self->port(7362);
	}
	if(defined($params{'Name'})) {
		$self->name($params{'Name'});
	} else {
		$self->name($self->id);
	}

	# Generate the XML-RPC URL from the parameters
	$self->{url} = 'http://'.$self->hostname.':'.$self->port.'/RPC2';
	$self->debug("Hostname is ".$self->hostname.", port is ".$self->port." and name is ".$self->name.".");
	$self->debug("XML-RPC URL is ".$self->url.".");

	# Initialise the RPC::XML::Client object
	$self->{_xmlrpc} = RPC::XML::Client->new($self->url);

	# Check connectivity with the fldigi client by checking the version
	$self->debug("Checking connectivity with fldigi client at ".$self->url."...");
	my $fldigi_version = $self->version;

	# If we get a version back, everything's fine.
	if(defined($fldigi_version)) {
		$self->debug("Version is ".$fldigi_version.".");
	} else {
		return undef;
	}

	# Return...
	$self->debug("Returning...");
	return $self;
}

=head1 METHODS

=head2 Client->command(I<command>, [I<arguments>])

Send command I<command>, with optional arguments I<arguments>.

=cut

sub command {

	my ($self, $cmd, $args) = @_;

	# If $args is unset, set it with an empty value
	if(!defined($args)) { $args = "" };

	$self->debug("Making XMLRPC call '".$cmd."' (args: ".$args.") to http://".$self->hostname.":".$self->port."/RPC2...");
	my $r = $self->_xmlrpc->simple_request($cmd, $args);

	# Check for undef response, which means there's been an error
	if($RPC::XML::ERROR ne "") {
		$self->error("Error talking to ".$self->url."!");
		$self->error("RPC::XML::Client reports: ".$RPC::XML::ERROR);
		return undef;
	}

	# If there's no response from XMLRPC, set it to '(null)'
	if(!defined($r)) { $r = "(null)"; };

	$self->debug("Response from XMLRPC request is: ".$r);
	return $r;
}

=head2 Client->version

Query for the version of Fldigi.

=cut

sub version {

	my ($self) = @_;
	my $r = $self->command('fldigi.version');

	return $r;

}

=head2 Client->send("I<text>")

Clears the TX window of any existing text, adds the text passed as I<text>, and then transmits. It automatically adds a '^r' at the end to tell Fldigi to switch back to RX afterwards.

=cut

sub send {

	my ($self, $text) = @_;

	# Clear the TX window of any existing text, add our text and then switch to TX.
	# We add a '^r' on the end to tell fldigi to stop once it's transmitted all
	# the waiting text.
	$self->command("text.clear_tx");
	$self->command("text.add_tx", $text."^r");
	$self->command("main.tx");

}

1;
__END__

=head1 SEE ALSO

The source code for this module is hosted on Github at L<https://github.com/m0vkg/Perl-Ham-Fldigi>.

=head1 AUTHOR

Andy Smith M0VKG, E<lt>andy@m0vkg.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andy Smith

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
