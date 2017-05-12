package IBM::StorageSystem::Drive;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(id status error_sequence_number use UID tech_type capacity block_size 
vendor_id product_id FRU_part_number FRU_identity RPM firmware_level FPGA_level 
mdisk_id mdisk_name member_id enclosure_id slot_id node_id node_name quorum_id 
port_1_status port_2_status);

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

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Drive - Class for operations with a IBM StorageSystem drive

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Drive is a utility class for operations with a IBM StorageSystem drive.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Get drive ID 2 as an IBM::StorageSystem::Drive object - note that drive ID 2 
	# is not necessarily the physical disk in slot ID 2 - see notes below.
	my $drive = $ibm->drive( 2 );

	# Print the drive capacity in bytes
	print $drive->capacity;
	
	# Print the drive vendor and product IDs
	print "Vendor ID: ", $drive->vendor_id, " - Product ID: ", $drive->product_id, "\n";
	
	# Print the SAS port status and drive status for all drives in a nicely formatted list
	printf("%-20s%-20s%-20s%-20s\n", 'Drive', 'SAS Port 1 Status', 'SAS Port 2 Status', 'Status');
	printf("%-20s%-20s%-20s%-20s\n", '-'x18, '-'x18, '-'x18, '-'x18);
	map { printf( "%-20s%-20s%-20s%-20s\n", $_->id, $_->port_1_status, $_->port_2_status, $_->status) } $ibm->get_drives;

	# e.g.
	# Drive               SAS Port 1 Status   SAS Port 2 Status   Status              
	# ------------------  ------------------  ------------------  ------------------  
	# 0                   online              online              online              
	# 1                   online              online              online              
	# 2                   online              online              online              
	# 3                   online              online              online
	# ...

	# Print the drive ID, slot ID, MDisk name and member ID of all drives
        foreach my $drive ( $ibm->get_drives ) { 
                print '-'x50, "\n";
                print "Drive ID  : " . $drive->id . "\n";
                print "Slot ID   : " . $drive->slot_id . "\n";
                print "MDisk ID  : " . $drive->mdisk_name . "\n";
                print "Member ID : " . $drive->member_id . "\n";
        } 

	# e.g.	
	# --------------------------------------------------
	# Drive ID  : 0
	# Slot ID   : 17
	# MDisk ID  : host-9
	# Member ID : 3
	# --------------------------------------------------
	# Drive ID  : 1
	# Slot ID   : 19
	# MDisk ID  : host-2
	# Member ID : 11
	# --------------------------------------------------
	# Drive ID  : 2
	# Slot ID   : 19
	# MDisk ID  : host-1
	# Member ID : 8
	# --------------------------------------------------
	# ... etc.


=head1 METHODS

=head3 FPGA_level

Returns the Field Programmable Gate Array (FPGA) level of the drive.

=head3 FRU_identity

Returns Field Replacable Unit (FRU) identity number of the drive.

=head3 FRU_part_number

Returns FRU part number of the drive.

=head3 RPM

Returns the Revolutions Per Minute (RPM) spindle rating of the drive.

=head3 UID

Returns Unique Identifier (UID) of the drive.

=head3 block_size

Returns drive block size.

=head3 capacity

Returns the drive capacity in bytes.

=head3 enclosure_id

Returns the ID of the enclosure in which the drive is physically located.

=head3 error_sequence_number

Returns the most recent error sequence number (if any).

=head3 firmware_level

Returns the drive firmware level.

=head3 id

Returns the drive ID (see L<NOTES> section).

=head3 mdisk_id

Returns the mdisk ID number of which this drive is a member.

=head3 mdisk_name

Returns the mdisk name of which this drive is a member.

=head3 member_id

Returns the drive MDisk member ID number.

=head3 node_id

Returns the drive node ID.

=head3 node_name

Returns the drive node name.

=head3 port_1_status

Returns the drive SAS port 1 status.

=head3 port_2_status

Returns the drive SAS port 2 status.

=head3 product_id

Returns the drive product ID.

=head3 quorum_id

Returns the drive quorum ID.

=head3 slot_id

Returns the drive slot ID (see the L<NOTES> section).

=head3 status

Returns the drive status.

=head3 tech_type

Returns the drive technical type.

=head3 use

Returns the drive use type.

=head3 vendor_id

Returns the drive vendor ID.

=head1 NOTES

Note that the drive ID is not equivalent to the slot ID - the slot ID identifies the physical enclosure slot in which
the drive is located whereas the drive ID is used to uniquely identify the drive within the context of the StorageSystem system.

The member ID is used to identify the drive within the context of the MDisk of which it is a member.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-drive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Drive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Drive


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Drive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Drive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Drive>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Drive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

