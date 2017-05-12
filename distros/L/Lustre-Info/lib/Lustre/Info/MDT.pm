#
# Lustre OST/OSS subclass
#
# (C) 2010 Adrian Ulrich - <adrian.ulrich@id.ethz.ch>
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
package Lustre::Info::MDT;

use strict;
use constant PROCFS_MDS       => "/proc/fs/lustre/mds";

##########################################################################
# Creates a new MDT Object
sub new {
	my($classname, %args) = @_;
	my $self = { super=>$args{super}, mdtname=>$args{mdtname}, procpath=>PROCFS_MDS."/$args{mdtname}" };
	bless($self,$classname);
	return ( -d $self->{procpath} ? $self : undef );
}

##########################################################################
# Return name of MDT
sub get_name {
	my($self) = @_;
	return $self->{mdtname};
}

##########################################################################
# Return the size of this MDT
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

Lustre::Info::MDT - MDT Object provided by Lustre::Info::get_mdt

=head1 METHODS

=over 4

=item get_name

Return name of this MDT

=item get_kbytes_total

Size of hosting blockdevice in kilobytes

=item get_kbytes_free

Returns the number of free kilobytes on the hosting blockdev

=item get_files_total

Returns the maximal number of inodes available on this MDT

=item get_files_free

Returns the number of unused inodes of this MDT

=item get_recovery_info

Returns a hashref with information about the last recovery

=back

=head1 AUTHOR

Copyright (C) 2010, Adrian Ulrich E<lt>adrian.ulrich@id.ethz.chE<gt>

=head1 SEE ALSO

L<Lustre::Info>,
L<Lustre::Info::OST>,
L<Lustre::Info::Export>,
L<http://www.lustre.org>

=cut
