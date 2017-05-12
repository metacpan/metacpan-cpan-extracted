package IBM::StorageSystem::VDisk::Copy;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(autoexpand capacity copy_id easy_tier easy_tier_status fast_write_state 
free_capacity grainsize mdisk_grp_id mdisk_grp_name mdisk_id mdisk_name overallocation 
primary real_capacity se_copy status sync tier tier_capacity type used_capacity 
vdisk_id vdisk_name warning);

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
        defined $args{copy_id} or croak 'Constructor failed: mandatory copy_id argument not supplied';
        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::VDisk::Copy - Class for operations with IBM StorageSystem VDisk Copies

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::VDisk::Copy - Class for operations with IBM StorageSystem VDisk Copies

	use IBM::StorageSystem;
        
	my $ibm = IBM::StorageSystem->new( user            => 'admin',
			 	   host            => 'my-v7000',
				   key_path        => '/path/to/my/.ssh/private_key'
			) or die "Couldn't create object! $!\n";

	# Print the status of copy 0 of VDisk 0
	print "Status: " . $ibm->vdisk(0)->copy(0)->status . "\n";

	# Print each VDisk by name and each of the VDisk copies status
	foreach my $vdisk ( $ibm->get_vdisks ) { 
        	print "VDisk : " . $vdisk->name . "\n";

        	foreach my $copy ( $vdisk->get_copys ) { 
        	        printf( "\tCopy: %-2s - Status : %-20s\n", $copy->copy_id, $copy->status )
        	}   
	}


=head1 METHODS

=head3 autoexpand

Specifies whether autoexpand is enabled on a space-efficient volume. The value can be on or off.

=head3 capacity

Returns the volume copy capacity in bytes.

=head3 copy_id

Specifies a system-assigned identifier for the volume copy. The value can be 0 or 1.

=head3 easy_tier

This value is set by the user and determines whether Easy Tier(R) is permitted to manage the pool.

B<Note:>

=over 3

=item 1. 

If easy_tier is on, then easy_tier_status can take on any value.

=item 2. 

if easy_tier is off, then easy_tier_status is measured or inactive.

=back

=head3 easy_tier_status

Which Easy Tier functions are active for the volume copy:

=over 3

=item Active 

May move extents of this volume copy for performance (automatic data placement).

=item Measured

Statistics are being gathered for this volume copy, but no extents will be moved.

=item Inactive 

No Easy Tier function is active.

=back

=head3 fast_write_state

Specifies the cache state of the volume copy. The value can be B<empty>, B<not_empty>, B<corrupt>, or
B<repairing>. The value is always empty for non-space-efficient copies. A cache state of
B<corrupt> indicates that the volume is space-efficient and requires repair that is initiated by
a B<recovervdisk> command or the B<repairsevdiskcopy> command.

=head3 free_capacity

Specifies the difference between the B<real_capacity> and used_capacity values.

B<Remember>: This value is zero for fully-allocated copies.

=head3 grainsize

For space-efficient volume copies, returns the copy grain size chosen at creation time.

=head3 mdisk_grp_id

Returns the volume copy MDisk group numerical ID.

=head3 mdisk_grp_name

Returns the volume copy MDisk group name.

=head3 mdisk_id

Specifies the ID of the storage pool that the volume copy belongs to.

=head3 mdisk_name

Specifies the name of the storage pool that the volume copy belongs to.

=head3 overallocation

Expressed as a percentage, specifies the ratio of volume capacity to B<real_capacity> values. 
This value is always B<100> for non-space-efficient volumes.

=head3 primary

Indicates whether the volume copy is the primary copy. A volume has exactly one primary copy. 
The value can be B<yes> or B<no>.

=head3 real_capacity

Specifies the amount of physical storage that is allocated from an storage pool to this volume copy. If
the volume copy is not space-efficient, the value is the same as the volume capacity. If the volume copy is
space-efficient, the value can be different.

B<Remember>: This value is the same as the volume capacity value for fully-allocated copies.

=head3 se_copy

Specifies if the copy is space-efficient.

=head3 status

The value can be B<online> or B<offline>. A copy is offline if all nodes cannot access the storage pool
that contains the copy.

=head3 sync

Indicates whether the volume copy is synchronized.

=head3 tier

Which tier information is being reported: B<generic_ssd> or B<generic_hdd>.

B<Note> that this method returns an array of the available tier types and that the ordering
of these types is preserved from the CLI output.  The ordering of these types can be used to 
retrieve the tier capacity of each tier type with the B<tier_capacity> command.

=head3 tier_capacity

The total MDisk capacity assigned to the volume in the tier.

B<Note>: For space-efficient copies, the capacity by tier will be the real capacity.

B<Also Note> that this method returns an array of all values of tier capacity the index of
which corresponds with the array indexes of tier types as returned by the B<tier> method.

For example, to print each tier type and the corresponding tier capacity for a copy:

	my $copy = $ibm->vdisk(0)->copy(0);

	for ( my $i = 0; $i < scalar @{ $copy->tier } ; $i++ ) {
		print "Tier: " . $copy->tier->[$i] .
			" - Capacity: " . $copy->tier_capacity->[$i] . "\n"
	}

=head3 type

Specifies the virtualization type of the volume. The value can be B<striped>, B<sequential> or
B<image>.

=head3 used_capacity

Specifies the portion of B<real_capacity> that is being used to store data. For non-space-efficient
copies, this value is the same as the volume capacity. If the volume copy is space-efficient, the value
increases from zero to the B<real_capacity> value as more of the volume is written to.

B<Remember>: This value is the same as the volume capacity value for fully-allocated copies.

=head3 vdisk_id

Returns the VDisk numerical ID of the volume copy.

=head3 vdisk_name

Returns the VDisk name of the volume copy.

=head3 warning

Expressed as a percentage, for space-efficient volume copies only. A warning is generated when the ratio of
B<used_capacity> to volume capacity reaches the specified level.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-vdisk-copy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-VDisk::Copy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::VDisk::Copy


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-VDisk::Copy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-VDisk::Copy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-VDisk::Copy>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-VDisk::Copy/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

