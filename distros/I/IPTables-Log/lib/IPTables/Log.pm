#!/usr/bin/perl

#=======================================================================
# Log.pm / IPTables::Log
# $Id: Log.pm 21 2010-12-17 21:07:37Z andys $
# $HeadURL: https://daedalus.dmz.dn7.org.uk/svn/IPTables-Log/trunk/IPTables-Log/lib/IPTables/Log.pm $
# (c)2009 Andy Smith <andy.smith@netprojects.org.uk>
#-----------------------------------------------------------------------
#:Description
# This is the main IPTables::Log class.
#-----------------------------------------------------------------------
#:Synopsis
#
# use IPTables::Log;
# my $l = IPTables::Log->new;
# my $s = $l->create_set;
# my $r = $s->create_record({text => '...IN=eth0 OUT=eth1 MAC=00:...'});
# $r->parse;
# $s->add($r);
#=======================================================================

# The pod (Perl Documentation) for this module is provided inline. For a
# better-formatted version, please run:-
# $ perldoc Log.pm

=head1 NAME

IPTables::Log - Parse iptables/netfilter syslog messages.

=head1 SYNOPSIS

  use IPTables::Log;
  my $l = IPTables::Log->new;
  my $s = $l->create_set;
  my $r = $s->create_record({text => '...IN=eth0 OUT=eth1 MAC=00:...'});
  $r->parse;
  $s->add($r);
  
=head1 DEPENDENCIES

=over 4

=item * Carp - for error generation

=item * Class::Accessor - for accessor methods

=item * Data::GUID - for GUID generation

=item * NetAddr::IP - for the C<src> and C<dst> methods

=back

=cut

# Set our package name
package IPTables::Log;

# Set minimum version of Perl
use 5.010000;
# Use strict and warnings
use strict;
use warnings;

# Use Carp for errors
use Carp;
# Use IPTables::Log::Set
use IPTables::Log::Set;

# Inherit from Class::Accessor to simplify accessor methods.
use base qw(Class::Accessor);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors( qw(raw debug) );

# Set version information
our $VERSION;
$VERSION = "0.0005";

# Hashes of colour
my $clr = "[0m";
my $bold = "[1m";
my $fclr = {'red' => '[31;1m',
			'green' => '[32;1m',
			'yellow' => '[33;1m',
			'blue' => '[34;1m',
			'purple' => '[35;1m',
			'cyan' => '[36;1m'};

my $bclr = {'red' => '[41;1m',
			'green' => '[42;1m',
			'yellow' => '[43;1m',
			'blue' => '[44;1m',
			'purple' => '[45;1m',
			'cyan' => '[46;1m'};

# Generates a debug message if $self->debug == 1
sub debug
{
	my ($self, $msg) = @_;

	if($self->get_debug)
	{
		print $bclr->{blue}.$fclr->{yellow}."D".$clr." ".$fclr->{green}.__PACKAGE__.$clr." ".$fclr->{purple}.$VERSION.$clr." | ".$msg."\n";
	}
}

# As above, but doesn't append a newline
sub debug_nolf
{
	my ($self, $msg) = @_;

	if($self->get_debug)
	{
		print $bclr->{blue}.$fclr->{yellow}."D".$clr." ".$msg;
	}
}

# As per $self->debug, but prints additional information in a chosen colour
sub debug_value
{
	my ($self, $text, $colour, $value) = @_;

	$self->debug($text." ".$self->fcolour($colour, $value));
}

# Prints an error to STDERR
sub error
{
	my ($self, $msg) = @_;

	print STDERR $fclr->{red}."E".$clr." ".$msg."\n";
}

# Prints and error to STDERR, then 'croak's
sub fatal
{
	my ($self, $msg) = @_;

	croak $bclr->{red}.$bold."!".$clr." ".$msg."\n";
}

# Wrap given message in ANSI colour codes
sub fcolour
{
	my ($self, $colour, $text) = @_;

	return $fclr->{$colour}.$text.$clr;
}

=head1 CONSTRUCTORS

=head2 Log->new

Creates a new C<IPTables::Log> object.

=head1 METHODS

=head2 $log->create_set(I<no_header => 0|1>)

Creates a new C<IPTables::Log::Set> object.

Setting I<no_header> to B<1> makes L<IPTables::Log::Set::Record> assume that the timestamp and hostname at the beginning of the message is missing (for example, if it's already been processed by another utility).

See L<IPTables::Log::Set> and L<IPTables::Log::Set::Record> for further details.

=cut

sub create_set
{
	my ($self, $args) = @_;

	$args->{'log'} = $self;

	my $set = IPTables::Log::Set->create($args);

	return $set;
}

=head1 CAVEATS

It parses log entries. It doesn't do much else, yet.

=head1 BUGS

None that I'm aware of ;-)

=head1 AUTHOR

This module was written by B<Andy Smith> <andy.smith@netprojects.org.uk>.

=head1 COPYRIGHT

$Id: Log.pm 21 2010-12-17 21:07:37Z andys $

(c)2009 Andy Smith (L<http://andys.org.uk/>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1
