#
# Lustre OST/OSS subclass
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#
package Lustre::Info::OST;
use strict;
use warnings;
use constant PROCFS_OBDFILTER => '/proc/fs/lustre/obdfilter';

my @TRACK_FIELDS = qw(write_bytes read_bytes create destroy setattr ping preprw);

sub new {
	my($classname, %args) = @_;
	my $self = { super=>$args{super}, ostname=>$args{ostname}, procpath=>PROCFS_OBDFILTER."/$args{ostname}", ost_stats=> [ {}, {} ], client_stats=>{} };
	bless($self,$classname);
	return ( -d $self->{procpath} ? $self : undef );
}


##########################################################################
# Return name of OST
sub get_name {
	my($self) = @_;
	return $self->{ostname};
}

##########################################################################
# Return the size of this OST
sub get_kbytes_total { return $_[0]->_rint('kbytestotal'); }

##########################################################################
# Return how much space is free
sub get_kbytes_free { return $_[0]->_rint('kbytesfree'); }

##########################################################################
# # of pre-allocated inodes (at mkfs.lustre runtime)
sub get_files_total { return $_[0]->_rint('filestotal'); }

##########################################################################
# How many files/inodes are free
sub get_files_free { return $_[0]->_rint('filesfree'); }

##########################################################################
# Returns the name of the hosting blockdevice
sub get_blockdevice { return $_[0]->_rint('mntdev'); }

##########################################################################
# Parse and return information about the last recovery procedure
sub get_recovery_info {
	my($self) = @_;
	return $self->{super}->_parse_generic_file($self->{procpath}."/recovery_status");
}

##########################################################################
# Update stats of this OST
sub collect_ost_stats {
	my($self) = @_;
	my $data  = $self->{super}->_parse_stats_file($self->{procpath}."/stats");
	my $stats = $self->{ost_stats};
	shift(@$stats);
	push(@{$stats}, $data);
	return $stats;
}

##########################################################################
# Return stats for this OST
sub get_ost_stats {
	my($self) = @_;
	
	my $a = $self->{ost_stats}->[0];
	my $b = $self->{ost_stats}->[1];
	my $r = {};
	return undef if !exists($a->{data}); # not enough data
	return undef if !exists($b->{data});
	
	$r->{_slice} = $b->{timestamp} - $a->{timestamp};
	foreach my $k (@TRACK_FIELDS) {
		$r->{$k} = $b->{data}->{$k}->{count} - $a->{data}->{$k}->{count} if
		    exists($a->{data}->{$k}) && exists($b->{data}->{$k});
	}
	return $r;
}


##########################################################################
# Collect statistics for ALL connected clients of this OST. This is expensive!
sub collect_client_stats {
	my($self, $clist) = @_;
	
	$clist = $self->get_exports if !$clist;
	
	foreach my $eid (@$clist) {
		my $data = $self->{super}->_parse_stats_file($self->{procpath}."/exports/$eid/stats") or next;
		if(!exists($self->{client_stats}->{$eid})) {
			$self->{client_stats}->{$eid} = [ {}, {} ]; # init empty struct on first run
		}
		
		my $ref = $self->{client_stats}->{$eid};
		shift(@$ref);
		push(@$ref, $data);
	}
	return $self->{client_stats}; # return most recent entry.
}

##########################################################################
# Returns statistics for all clients on this OST
sub get_client_stats {
	my($self) = @_;
	
	my $r = {};
	foreach my $eid (keys(%{$self->{client_stats}})) {
		my $this_ref = $self->{client_stats}->{$eid};  # holds: [ {timestamp=>0, data=>{}}, {timestamp=>0, data=>{}} ]
		my $a        = $this_ref->[0];
		my $b        = $this_ref->[1];
		next if !exists($a->{data}) or !exists($b->{data}); # all zero or not enough data;
		
		$r->{$eid}->{_slice} = $b->{timestamp} - $a->{timestamp};
		map { $r->{$eid}->{$_} = 0 } @TRACK_FIELDS;
		
		foreach my $k (@TRACK_FIELDS) {
			$r->{$eid}->{$k} = $b->{data}->{$k}->{count} - $a->{data}->{$k}->{count} if
			   exists($a->{data}->{$k}) && exists($b->{data}->{$k});
		}
	}
	return $r;
}

##########################################################################
# Returns a list to all 'known' exports of this OST
sub get_exports {
	my($self) = @_;
	
	my @list = ();
	opendir(PD, $self->{procpath}."/exports/") or return \@list;
	while(defined(my $dirent = readdir(PD))) {
		next if $dirent eq '.';
		next if $dirent eq '..';
		next unless -d $self->{procpath}."/exports/$dirent";
		push(@list,$dirent);
	}
	closedir(PD);
	return \@list;
}



##########################################################################
# Return an integer
sub _rint {
	my($self,$procfile) = @_;
	open(PF, $self->{procpath}."/$procfile") or return -1;
	my $num = <PF>; chomp($num);
	close(PF);
	return $num;
}


1;
__END__

=head1 NAME

Lustre::Info::OST - OST Object provided by Lustre::Info::get_ost

=head1 METHODS

=over 4

=item get_name

Return name of this OST

=item get_kbytes_total

Size of hosting blockdevice in kilobytes

=item get_kbytes_free

Returns the number of free kilobytes on the hosting blockdev

=item get_files_total

Returns the maximal number of inodes available on this OST

=item get_files_free

Returns the number of unused inodes of this OST

=item get_recovery_info

Returns a hashref with information about the last recovery

=item collect_ost_stats

Collect a new performance sample for this ost. You are supposed to
call this in a loop. See also C<lustre-info.pl>

=item get_ost_stats

Returns a rather big hashref with collected statistics.
Will return undef if there is not enough data (needs at least
two calls of collect_ost_stats)

=item collect_client_stats

Almost the same as C<collect_ost_stats> but collects statistics
for each nid/export/client

=item get_client_stats

Returns a very big hashref with collected client statistics.

=item get_exports

Returns a array-ref with all known exports of this ost.

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::Info>,
L<Lustre::Info::Export>,
L<Lustre::Info::MDT>,
L<http://www.lustre.org>

=cut
