package IBM::StorageSystem::Array;

use strict;
use warnings;

use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(UID active_WWPN balanced block_size capacity controller_id controller_name 
ctrl_LUN_no ctrl_WWNN ctrl_type fast_write_state max_path_count mdisk_grp_id mdisk_grp_name 
mdisk_id mdisk_name mode path_count preferred_WWPN quorum_index raid_level raid_status 
redundancy spare_goal spare_protection_min status strip_size tier);

foreach my $attr ( @ATTR ) { 
        {   
                no strict 'refs';
                *{ __PACKAGE__ .'::'. $attr } = sub {
                        my( $self, $val ) = @_;
			$val =~ s/\#/no/ if $val; 
                        $self->{$attr} = $val if $val;
                        return $self->{$attr}
                }   
        }   
}

sub new {
        my( $class, $ibm, %args ) = @_; 
        my $self = bless {}, $class;
        defined $args{mdisk_id} or croak 'Constructor failed: mandatory mdisk_id argument not supplied';
	weaken( $self->{__ibm} = $ibm );

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Array - Class for operations with a IBM StorageSystem array

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Array is a utility class for operations with a IBM StorageSystem array.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

        # Get array 2 as an IBM::StorageSystem::Array object
	my $array = $ibm->array( 2 );
	
	# Print the array capacity
	print $array->capacity;

	# Print the array RAID level
	print $array->raid_level;

	# Alternately -	print $ibm->array( 2 )->raid_level

	# Print the array status of all arrays in our system
	map { print "Array ", $_->mdisk_id, " status ", $_->status, "\n" } $ibm->get_arrays;

=head1 METHODS

=head3 UID

Returns the array UID.

=head3 active_WWPN

Returns the array active WWPN.

=head3 balanced

Describes if the array is balanced to its spare goals:

=over 4

=item * exact - All populated members have exact capability match, exact location match.

=item * yes - All populated members have at least exact capability match, exact chain, or different enclosure or slot.

=item * no - Anything else.

=back

=head3 block_size

Returns the array block size 512 bytes (or blank) in each block of storage.

=head3 capacity

Returns the array capacity in bytes.

=head3 controller_id

Returns the array controller id.

=head3 controller_name

Returns the array controller name.

=head3 ctrl_LUN_no

Returns the control LUN number.

=head3 ctrl_WWNN

Returns the control LUN WWNN.

=head3 ctrl_type

Returns the array control type - either 4 or 6, where 6 is a solid-state drive (SSD) attached 
inside a node and 4 is any other device.

This value may be null for Unified systems.

=head3 fast_write_state

Returns the array fast write state.

=head3 max_path_count

Returns the array maximum path count.

=head3 mdisk_grp_id

Returns the array MDisk group IO identity.

=head3 mdisk_grp_name

Returns the array MDisk group name.

=head3 mdisk_id

Returns the identity of the array MDisk.

=head3 mdisk_name

Returns the array MDisk name.

=head3 mode

Returns the array mode; either unmanaged, managed, image or array.

=head3 path_count

Returns the array path count.

=head3 preferred_WWPN

Returns the array preferred WWPN.

=head3 quorum_index

Returns the array quorum index; 0, 1, 2, or blank if the MDisk is not being used
as a quorum disk.

=head3 raid_level

Returns the RAID level of the array (RAID0, RAID1, RAID5, RAID6, RAID10). 

=head3 raid_status

Returns the array RAID status:

=over 4

=item * offline - the array is offline on all nodes.

=item * degraded - the array has deconfigured or offline members; the array is not fully redundant.

=item * syncing - array members are all online, the array is syncing parity or mirrors to achieve redundancy.

=item * initting - array members are all online, the array is initializing; the array is fully redundant.

=item * online - array members are all online, and the array is fully redundant 

=back

=head3 redundancy

Returns the number of member disk that can fail before the array fails.

=head3 spare_goal

Returns the number of spares that array members should be protected by.

=head3 spare_protection_min

Returns the minimum number of spares that an array member is protected by.

=head3 status

Returns the array status; either online, offline, excluded or degraded.

=head3 strip_size

Returns the array strip size in KB.

=head3 tier

Returns the tier that the MDisk has been assigned to by auto-detection (for internal
arrays) or by the user.  Either generic_ssd or generic_hdd.

=head1 AUTHOR

Luke Poskitt, C<< <ltp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ibm-v7000-array at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IBM-StorageSystem-Array>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IBM::StorageSystem::Array


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IBM-StorageSystem-Array>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IBM-StorageSystem-Array>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IBM-StorageSystem-Array>

=item * Search CPAN

L<http://search.cpan.org/dist/IBM-StorageSystem-Array/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Luke Poskitt.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

