#!/usr/bin/perl

#=======================================================================
# Set.pm / IPTables::Log::Set
# $Id: Set.pm 21 2010-12-17 21:07:37Z andys $
# $HeadURL: https://daedalus.dmz.dn7.org.uk/svn/IPTables-Log/trunk/IPTables-Log/lib/IPTables/Log/Set.pm $
# (c)2009 Andy Smith <andy.smith@netprojects.org.uk>
#-----------------------------------------------------------------------
#:Description
# This class holds a set of IPTables::Log::Set::Record objects
#-----------------------------------------------------------------------
#:Synopsis
# NOTE: This class isn't designed to be created directly.
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
# $ perldoc Set.pm

=head1 NAME

IPTables::Log::Set - Holds a set of IPTables::Log::Set::Record objects.

=head1 SYNOPSIS

Note that this class isn't designed to be created directly. You can create these objects via a C<IPTables::Log> object.

  use IPTables::Log;
  my $l = IPTables::Log->new;
  my $s = $l->create_set;

=head1 DEPENDENCIES

=over 4

=item * Class::Accessor - for accessor methods

=item * Data::GUID - for GUID generation

=item * NetAddr::IP - for the C<src> and C<dst> methods (required by L<IPTables::Log::Set::Record>)

=back

=cut

# Set our package name
package IPTables::Log::Set;

# Minimum version
use 5.010000;
# Use strict and warnings
use strict;
use warnings;

# Use Carp for erroring
use Carp;
# Use Data::GUID for generating GUIDs
use Data::GUID;
# Use IPTables::Log::Set::Record for individual log entries
use IPTables::Log::Set::Record;
# Use Data::Dumper
use Data::Dumper;

# Inherit from Class::Accessor to simplify accessor method generation
use base qw(Class::Accessor);
# Follow best practice
__PACKAGE__->follow_best_practice;
# Create log and guid as read-only accessor methods
__PACKAGE__->mk_ro_accessors( qw(log guid) );

# Set version information
our $VERSION = '0.0005';

=head1 CONSTRUCTORS

=head2 Set->create

Creates a new C<IPTables::Log::Set> object. This isn't the recommended way to do this, however. The proper way is to create an object via a L<IPTables::Log> object with C<create_set>.

=cut

sub create
{
	my ($class, $args) = @_;

	my $self = __PACKAGE__->new($args);
	$self->{records} = {};

	# Generate a GUID for the set
	my $g = Data::GUID->new;
	$self->{guid} = $g->as_string;
	$self->{no_header} = $args->{'no_header'};

	return $self;
}

=head1 METHODS

=head2 $set->create_record(I<{text => '...IN=eth0 OUT=eth1 MAC=00:...'}>))

Creates a new L<IPTables::Log::Set::Record> object. This is the B<recommended> way to create C<IPTables::Log::Set::Record> objects, as it ensures various settings are inherited from the C<Log> class.

The text of the log entry can be passed here, or it can be passed with the C<set_text> accessor method to the C<IPTables::Log::Set::Record> object itself.

=cut

sub create_record
{
	my ($self, $args) = @_;

	#$args->{log} = $self->get_log;

	my $record = IPTables::Log::Set::Record->create($args);

	return $record;
}

=head2 $set->load_file($filename)

Loads in logs from I<$filename>, discarding any which don't appear to be iptables/netfilter logs. A L<IPTables::Log::Set::Record> object is then created for each entry, and the content is then parsed. Finally, each entry is then added to the set created with C<create_record>.

=cut

sub load_file
{
	my ($self, $filename) = @_;

	# Check we've been passed a filename
	if(!$filename)
	{
		croak "No filename given to load_file().";
		#$self->get_log->fatal("No filename given!");
	}

	# Check that the file exists, and barf if not.
	if(!-f $filename)
	{
		croak $filename." does not exist.";
		#$self->get_log->fatal("Cannot find ".$self->get_log->fcolour('yellow', $filename));
	}

	#$self->get_log->debug("Opening ".$self->get_log->fcolour('yellow', $filename)."...");
	# Open the logfile
	open(LOGFILE, $filename) || $self->get_log->fatal("Cannot open ".$self->get_log->fcolour('yellow', $filename));
	my @logs = <LOGFILE>;
	#$self->get_log->debug("Finished reading in logs.");

	# It's a fair bet that if we don't have an IN= and an OUT= and it doesn't have a source of 'kernel', then it's not an iptables log.
	# We'll discard those before even attempting to parse it.
	foreach my $log (@logs)
	{
		if($log =~ /kernel.+IN=.+OUT=/)
		{
			chomp($log);
			#$self->get_log->debug_nolf("Parsing iptables log entry... ");
			my $record = $self->create_record({'text' => $log, 'no_header' => $self->{no_header}});
			$record->parse;
			#$self->get_log->debug("done.");
			$self->add($record);
			$self->get_log->debug("Added record with GUID ".$self->get_log->fcolour('yellow', $record->get_guid). " to set.");
			#return 1;
		}
		else
		{
			#$self->get_log->debug("Log entry is not an iptables log entry, so skipping...");
		}
	}
	return 1;
}

=head2 $set->add($record)

Adds a L<IPTables::Log::Set::Record> object to a set created with C<create_set>.

=cut

sub add
{
	my ($self, $record) = @_;

	if($record)
	{
		my $guid = $record->get_guid;

		$self->{records}{$guid} = $record;
	}
}

=head2 $set->get_by('field')

Returns a hash of record identifiers, indexed by I<field>. Field can be one of I<guid>, I<date>, I<time>, I<hostname>, I<prefix>, I<in>, I<out>, I<mac>, I<src>, I<dst>, I<proto>, I<spt>, I<dpt>, I<id>, I<len>, I<ttl>, I<df>, I<window>, I<syn>.

If you attempt to sort on a field that isn't present in all records in the set, get_by will only return records which have that field. For example, if you attempt to get_by('dpt'), any ICMP log messages will be silently excluded from the returned set.

=cut

sub get_by
{
	my ($self, $by) = @_;

	# Check that $by is set
	if($by)
	{
		# Create a hash to hold the index values
		my %indexes;
		$indexes{by} = $by;

		foreach my $r (keys %{$self->{records}})
		{
			# Step through each record.
			my $record = $self->{records}{$r};
			my $value = $record->get($by);

			# If $value is blank, it means not all records have this field.
			# For now, we'll refuse to add these.
			if($value)
			{
				if(!$indexes{$by}{$record->get($by)})
				{
					$indexes{$by}{$record->get($by)} = [];
				}
				push (@{$indexes{$by}{$record->get($by)}}, $record);
			}
		}

		return %indexes;
	}
}

=head1 CAVEATS

None.

=head1 BUGS

None that I'm aware of ;-)

=head1 AUTHOR

This module was written by B<Andy Smith> <andy.smith@netprojects.org.uk>.

=head1 COPYRIGHT

$Id: Set.pm 21 2010-12-17 21:07:37Z andys $

(c)2009 Andy Smith (L<http://andys.org.uk/>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1
