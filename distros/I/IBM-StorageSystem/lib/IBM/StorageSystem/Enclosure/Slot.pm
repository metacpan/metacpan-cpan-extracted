package IBM::StorageSystem::Enclosure::Slot;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(drive_id drive_present enclosure_id error_sequence_number fault_LED port_1_status port_2_status powered slot_id);

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
        defined $args{slot_id} or croak 'Constructor failed: mandatory argument slot_id not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Enclosure::Slot - Class for operations with a IBM Storwize enclosure slot

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Enclosure::Slot is a utility class for operations with a IBM Storwize enclosure slot.

        use IBM::StorageSystem;

        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                        ) or die "Couldn't create object! $!\n";

        # Print the corresponding slot and drive IDs for all populated slots
	# in all enclosures in this system.
	foreach my $enclosure ( $ibm->get_enclosures ) {

		foreach my $slot ( $ibm->enclosure($enclosure)->get_slots ) {
			print "Slot ", $slot->slot_id, " -> Drive ", $slot->drive_id, "\n"
				if ( $slot->drive_present eq 'yes' )
		}

	}

	# Will print something similar to:
	# Slot 1 -> Drive 3
	# Slot 2 -> Drive 1
	# Slot 3 -> Drive 8
	# ... etc.

=head3 drive_id

Returns the drive ID of the drive in the specified slot (if present).

=head3 drive_present

Returns the drive present status of the specified slot.

=head3 enclosure_id

Returns the enclosure_id of the enclosure in which the specified slot is present.

=head3 error_sequence_number

Returns the most recent error sequence number (if present) of the specified slot.

=head3 fault_LED

Returns the fault LED state of the specified slot.

=head3 port_1_status

Returns the first SAS port status of the specified slot.

=head3 port_2_status

Returns the second SAS port status of the specified slot.

=head3 powered

Returns the powered status of the specified slot.

=head3 slot_id

Returns the numerical IDof the specified slot

=cut

