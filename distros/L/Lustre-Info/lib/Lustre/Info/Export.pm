#
# Lustre NID/export Subclass
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Lustre::Info::Export;
use strict;
use warnings;


##########################################################################
# Returns a new Export Object
sub new {
	my($classname, %args) = @_;
	my $self = { super=>$args{super}, export=>$args{export}, export_stats=>{}, graph_stats=>[{},{}] };
	bless($self,$classname);
}

##########################################################################
# Return name of this nid
sub get_name {
	my($self) = @_;
	return $self->{export};
}

##########################################################################
# AB(uses) the OST-Module to get statistics for this client
sub collect_export_stats {
	my($self, $ostlist) = @_;
	
	$ostlist = $self->{super}->get_ost_list if !$ostlist;
	
	foreach my $ost (@$ostlist) {
		$self->{export_stats}->{$ost} ||= $self->{super}->get_ost($ost);        # Creates a new ost-object if empty
		$self->{export_stats}->{$ost}->collect_client_stats([$self->get_name]); # collect stats for this-client only
	}
	
	return undef;
}

##########################################################################
# Return per-ost statistics of this NID/EXPORT
sub get_export_stats {
	my($self) = @_;
	
	my $es = $self->{export_stats};
	my $r  = {};
	foreach my $ost_name (keys(%$es)) {
		my $ost_ref = $es->{$ost_name};
		my $stats   = $ost_ref->get_client_stats;
		$r->{$ost_name} = $stats->{$self->get_name};
	}
	return $r;
}

##########################################################################
# Undocumented alias for get_export_stats
sub get_client_stats {
	my($self) = @_;
	return $self->get_export_stats;
}

##########################################################################
# undocumented alias for collect_export_stats
sub collect_client_stats {
	my($self) = @_;
	return $self->collect_export_stats;
}

sub collect_brw_stats {
	my($self, $ostlist) = @_;
	
	$ostlist = $self->{super}->get_ost_list if !$ostlist;
	
	my $own_name = $self->get_name;
	my $tstamp   = 0;
	my $junk     = {};
	foreach my $ost (@$ostlist) {
		my $pfs_file = "/proc/fs/lustre/obdfilter/$ost/exports/$own_name/brw_stats";
		next unless -f $pfs_file;
		my $ref = $self->{super}->_parse_brw_file($pfs_file);
		$tstamp ||= $ref->{timestamp};
		$junk = $self->{super}->sum_up_deep(2, $ref->{data}, $junk);
	}
	
	$junk->{timestamp} = $tstamp; # Add first timestamp to ref (as expected by get_*_stats)
	
	my $stats_ref = $self->{graph_stats};
	shift(@$stats_ref);
	push(@$stats_ref, $junk);
	return $junk;
}

sub get_brw_stats {
	my($self) = @_;
	
	my $r1   = $self->{graph_stats}->[0];
	my $r2   = $self->{graph_stats}->[1];
	my $ts1  = $r1->{timestamp} or return undef;
	my $ts2  = $r2->{timestamp} or return undef;
	my $junk = {};
	
	foreach my $label (keys(%$r1)) {
		my $rx = $r1->{$label};
		next if ref($rx) ne 'HASH';
		next if !exists($r2->{$label});
		
		foreach my $line (keys(%$rx)) {
			next if !exists($r2->{$label}->{$line});
			foreach my $action (keys(%{$rx->{$line}})) {
				my $value = $r2->{$label}->{$line}->{$action} - $r1->{$label}->{$line}->{$action};
				$junk->{$label}->{$line}->{$action} = $value;
			}
		}
	}
	return({_slice=>($ts2-$ts1), data=>$junk});
}


1;
__END__

=head1 NAME

Lustre::Info::Export - Export (clients) Object provided by Lustre::Info::get_export

=head1 METHODS

=over 4

=item get_name

Return name of this Export

=item collect_export_stats

Collect a new performance sample for this export. You are supposed to
call this in a loop. See also C<lustre-info.pl>

=item get_export_stats

Returns a rather big hashref with collected statistics.
Will return undef if there is not enough data (needs at least
two calls of collect_export_stats)

=item collect_brw_stats

Collects detailed io-pattern statistics (service time, io-size...)

=item get_brw_stats

Returns a very big hashref with collected brw_stats.

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::Info>,
L<Lustre::Info::OST>,
L<Lustre::Info::MDT>,
L<http://www.lustre.org>

=cut
