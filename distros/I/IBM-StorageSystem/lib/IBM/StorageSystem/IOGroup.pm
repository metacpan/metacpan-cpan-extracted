package IBM::StorageSystem::IOGroup;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(accessible_vdisk_count compression_active compression_supported 
flash_copy_free_memory flash_copy_total_memory host_count id maintenance 
mirroring_free_memory mirroring_total_memory name node_count raid_free_memory 
raid_total_memory remote_copy_free_memory remote_copy_total_memory vdisk_count);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_; 
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
        defined $args{'id'} or croak __PACKAGE__ 
		. ' constructor failed: mandatory id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::IOGroup - Class for operations with IBM StorageSystem I/O Groups

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::IOGroup is a utility class for operations with IBM StorageSystem I/O Groups.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Get I/O group 0
	my $io_group = $ibm->get_iogroup(0);

	# Print the I/O group maintenance state
	print $io_group->maintenance_state;

	# Alternately:
	print $ibm->iogroup(0)->maintenance_state;

	# Print a formatted listing of all I/O groups by ID and name, along with
	# their VDisk count, host count, node count and maintenance state.
	map { printf("%-8s%-20s%-20s%-20s%-20s%-20s\n", 
		$_->id,
		$_->name,
		$_->vdisk_count,
		$_->host_count,
		$_->node_count,
		$_->maintenance )
	} $ibm->get_iogroups;

	# Prints something like:
	#
	# ID      Name                VDisk Count         Host Count          Node Count          Maintenance         
	# 0       io_grp0             2                   3                   2                   no                  
	# 1       io_grp1             0                   3                   0                   no                  
	# 2       io_grp2             0                   3                   0                   no                  
	# 3       io_grp3             0                   3                   0                   no
	# ... etc.

=head1 METHODS

=head3 accessible_vdisk_count

Returns the number of accessible volumes in this I/O group.

=head3 compression_active

Returns the I/O group volume compression support state.

=head3 compression_supported

Indicates if the I/O group supports compressed volumes.

=head3 flash_copy_free_memory

Returns the I/O groups free flash copy memory in bytes.

=head3 flash_copy_total_memory

Returns the I/O groups total flash copy memory in bytes.

=head3 host_count

Returns the number of hosts attached to the I/O group.

=head3 id

Returns the I/O groups numerical identifier.

=head3 maintenance

Returns the maintenance state of the I/O group.

=head3 mirroring_free_memory

Returns the I/O groups mirroring free memory in bytes.

=head3 mirroring_total_memory

Returns the I/O groups total mirroring memory in bytes.

=head3 name

Returns the name of the I/O group.

=head3 node_count

Returns the attached node count of the I/O group.

=head3 raid_free_memory

Returns the I/O groups RAID free memory in bytes.

=head3 raid_total_memory

Returns the I/O groups RAID total memory in bytes.

=head3 remote_copy_free_memory

Returns the I/O groups remote copy free memory in bytes.

=head3 remote_copy_total_memory

Returns the I/O groups total remote copy memory in bytes.

=head3 vdisk_count

Returns the I/O groups VDisk count.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-iogroup at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-IOGroup>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::IOGroup


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-IOGroup>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-IOGroup>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-IOGroup>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-IOGroup/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

