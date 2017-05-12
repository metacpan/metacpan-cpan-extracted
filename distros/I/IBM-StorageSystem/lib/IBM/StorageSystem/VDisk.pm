package IBM::StorageSystem::VDisk;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken);
use IBM::StorageSystem::VDisk::Copy;

our $VERSION = '0.01';
our @ATTR = qw(FC_id FC_name IO_group_id IO_group_name RC_change RC_id RC_name cache 
capacity copy_count fast_write_state fc_map_count filesystem formatted id mdisk_grp_id 
mdisk_grp_name mdisk_id mdisk_name mirror_write_priority name preferred_node_id 
se_copy_count status sync_rate throttling type udid vdisk_UID);

our $OBJ = {
		copy => {
			bcmd	=> 'lsvdiskcopy -nohdr -delim :',
			cmd	=> 'lsvdiskcopy -bytes -copy',
			id	=> 'copy_id',
			class	=> 'IBM::StorageSystem::VDisk::Copy',
			type	=> 'copy'
		}
	};

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
        defined $args{id} or croak 'Constructor failed: mandatory id argument not supplied';
	weaken( $self->{__ibm } = $ibm );

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

foreach my $obj ( keys %{ $OBJ } ) { 
        {
                no strict 'refs';
                my $m = 'get_'.$obj.'s';

                *{ __PACKAGE__ ."::$obj" } = sub {
                        my( $self, $id ) = @_; 
                        defined $id or return;
                        return ( $self->{$obj}->{$id} ? $self->{$obj}->{$id} : $self->$m( $id ) ) 
                };  
    
                *{ __PACKAGE__ .'::get_'. $obj } = sub { return $_[0]->$m( $_[1] ) };

                *{ __PACKAGE__ ."::$m" } = sub {
                        my( $self, $id ) = @_; 

                        my @objects = map { ( split /:/, $_ )[2] . " $self->{id}" } 
				      split /\n/, $self->{__ibm}->__cmd( "$OBJ->{ $obj }->{ bcmd } $self->{ id }");

                        my %a = (objects=> [ @objects ], 
				 cmd	=> $OBJ->{ $obj }->{ cmd },
				 class	=> $OBJ->{ $obj }->{ class },
				 nocache=> 1 );
                        @objects = $self->{__ibm}->__get_ml_objects( %a );

                        foreach my $object ( @objects ) { 
                                $self->{ $OBJ->{ $obj }->{ type } }->{ $object->{ $OBJ->{ $obj }->{ id } } } = $object
                        }

                        return ( defined $id ? $self->{ $OBJ->{ $obj }->{ type } }->{ $id } : @objects )
                }
        }
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::VDisk - Class for operations with IBM StorageSystem VDisks

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::VDisk - Class for operations with IBM StorageSystem VDisks

	use IBM::StorageSystem;
        
	my $ibm = IBM::StorageSystem->new( user            => 'admin',
			 	   host            => 'my-v7000',
				   key_path        => '/path/to/my/.ssh/private_key'
			) or die "Couldn't create object! $!\n";

	# Get the VDisk ID 3 and print the VDisk UUID
	my $vdisk = $ibm->vdisk(3);
	print $vdisk->vdisk_UUID;

	# Alternately:
	print $ibm->vdisk(3)->vdisk_UUID;

	# Print the name, ID, capacity in GB and MDisk group name of all VDisks in a
	# nicely formatted output
	printf( "%-20s%-8s%-15s%20s\n", 'Name', 'ID', 'Capacity (GB)', 'MDisk Group Name' );
	printf( "%-20s%-8s%-15s%20s\n", '-'x18, '-'x4, '-'x12, '-'x15 );
	map { printf( "%-20s%-8s%-15s%20s\n", $_->name, $_->id, (int($_->capacity / (1024**3))), $_->mdisk_grp_name) } 
	grep { $_->status eq 'online' } $ibm->get_vdisks;

	# Should print something like:
	# Name                ID      Capacity (GB)      MDisk Group Name
	# ------------------  ----    ------------       ---------------
	# file-host-1         0       5823               FILE_POOL
	# backup-host-2       1       2330               BACKUP_POOL
	# ... etc.

=head1 METHODS

=head3 FC_id

Specifies the ID of the FlashCopy mapping that the volume belongs to. The value B<many> indicates
that the volume belongs to more than one FlashCopy mapping.

=head3 FC_name

Specifies the name of the FlashCopy mapping that the volume belongs to. The value B<many> indicates
that the volume belongs to more than one FlashCopy mapping.

=head3 IO_group_id

Specifies the I/O Group that the volume belongs to.

=head3 IO_group_name

Specifies the I/O Group that the volume belongs to.

=head3 RC_change

Specifies if a volume is a change volume of a Global Mirror or Metro Mirror relationship.

=head3 RC_id

Specifies the ID of the Global Mirror or Metro Mirror relationship that the volume belongs to. The value must
be numerical.

=head3 RC_name

Specifies the name of the Global Mirror or Metro Mirror relationship that the volume belongs to.

=head3 cache

Specifies the cache mode of the volume. The value can be B<readwrite> or <none>.

=head3 capacity

Specifies the total capacity of the volume.

=head3 copy ( $id )

	# Get copy ID 0 of VDisk 0 and print the copy status
	my $copy = $ibm->vdisk(0)->copy(0);
	print $copy->status;

	# Or:
	print $ibm->vdisk(0)->copy(0)->status;

Returns the VDisk volume copy specified by the value of the numerical ID argument as an
L<IBM::StorageSystem::VDisk::Copy> object.

B<Note> that this method implements caching and will return a cached L<IBM::StorageSystem::VDisk::Copy>
object should one exist from a previous retrieval.  

B<Note> also that previous retrievals of such objects may happen implicitly on invocation of the B<copy>, 
B<get_copy>, or B<get_copys> methods so if you are certain that you wish to force any existing 
cached objects to be refreshed, then you should use the B<get_copy> or B<get_copys> methods.

=head3 get_copy ( $id )

Returns the VDisk volume copy specified by the value of the numerical ID argument as an
L<IBM::StorageSystem::VDisk::Copy> object.

B<Note> that this method is non-caching and will always force a retrieval of fresh information from the StorageSystem.

Doing so will usually result in a performance penalty - compare this with the operation of the caching
method B<copy>.

=head3 get_copys

	my @vdisks = $ibm->get_vdisks;

	foreach my $vdisk ( @vdisks ) {
		my @copies = $vdisk->get_copys;
		
		foreach my $copy ( @copies ) {
			print $copy->sync
		}
	}

Returns all VDisk copies for the specified VDisk as an array of L<IBM::StorageSystem::VDisk::Copy> objects.

B<Note> that this method is non-caching and the information is always retrieved from the target system
ignoring any cached results.

=head3 copy_count

Returns the copy count of the volume.

=head3 fast_write_state

Specifies the cache state for the volume. The value can be B<empty>, B<not_empty>, B<corrupt>, or
B<repairing>. A cache state of B<corrupt> indicates that the volume requires recovery by using one
of the B<recovervdisk> commands. A cache state of B<repairing> indicates that repairs initiated by a
B<recovervdisk> command are in progress.

=head3 fc_map_count

Specifies the number of FlashCopy mappings that the volume belongs to.

=head3 filesystem

Expressed as a value string (long object name with a maximum of 63 characters), specifies the full name for
file system which owns this volume; otherwise, it is blank.

=head3 formatted

Indicates whether the volume was formatted when it was created. The value can be B<yes> or B<no>.

=head3 free_capacity

Specifies the difference between the B<real_capacity> and B<used_capacity> values.

=head3 id

Returns the VDisk numerical ID.

=head3 mdisk_grp_id

Specifies the ID of the storage pool that the volume belongs to. If the volume has more than one copy,
these fields display B<many>.

=head3 mdisk_grp_name

Specifies the name of the storage pool that the volume belongs to. If the volume has more than one copy,
these fields display B<many>.

=head3 mdisk_id

Specifies the MDisk numerical ID that is used for sequential and image mode volumes. If the volume has more 
than one copy, these fields display B<many>.

=head3 mdisk_name

Specifies the MDisk name that is used for sequential and image mode volumes. If the volume has more 
than one copy, these fields display B<many>.

=head3 mirror_write_priority

Specifies the mirror write algorithm priority being used if the volume is mirrored.

=head3 name

Specifies the volume name.

=head3 overallocation

Expressed as a percentage, specifies the ratio of volume capacity to B<real_capacity> values. This value is
always B<100> for non-space-efficient volumes.

B<Remember>: This value can be any percentage (but not blank) for compressed volume copies.

=head3 preferred_node_id

Specifies the ID of the preferred node for the volume.

B<Remember>: This value must be numeric. (The value is zero if no node is configured in the I/O group that
contains the preferred node.)

=head3 se_copy_count

Specifies the number of space-efficient copies.

B<Remember>:  This value represents only space-efficient copies and is not used for compressed volume
copies.

=head3 status

The value can be B<online>, B<offline> or B<degraded>.

=head3 sync_rate

Specifies the rate for synchronization for mirrored copies.

=head3 throttling

Specifies the throttle rate of the volume.

=head3 type

Specifies the virtualization type of the volume. The value can be B<striped>, B<sequential>,
B<image> or B<many>. The value B<many> indicates that the volume has more than one copy, which
can have different virtualization types.

=head3 udid

Specifies the unit number for the volume. Only OpenVMS hosts require a unit number.

=head3 vdisk_UID

Specifies the UID of the volume.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-vdisk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-VDisk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::VDisk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-VDisk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-VDisk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-VDisk>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-VDisk/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
