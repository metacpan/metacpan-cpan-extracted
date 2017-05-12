package IBM::StorageSystem::Enclosure::PSU;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(enclosure_id PSU_id status AC_failed DC_failed fan_failed redundant error_sequence_number FRU_part_number FRU_identity firmware_level_1 firmware_level_2);

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
        defined $args{PSU_id} or croak 'Constructor failed: mandatory id argument not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Enclosure::PSU - Class for operations with a IBM Storwize enclosure PSU

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Enclosure::PSU is a utility class for operations with a IBM Storwize enclosure PSU.

	use IBM::StorageSystem;

        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                        ) or die "Couldn't create object! $!\n";

	# Print the status of the second PSU in the fifth enclosure.
	print $ibm->enclosure(5)->psu(2)->status;

	# Print the status of all PSUs in all enclosures in our system
	map { print "\t- PSU ", $_->PSU_id, " status: ", $_->status, "\n" } 
	map { print "--- Enclosure ", $_->id, "\n"; $_->get_psus } $ibm->get_enclosures;

	# Should yield something similar to:
	# --- Enclosure 1
	#	- PSU 1 status: online
	#	- PSU 2 status: online
	# --- Enclosure 2
	#	- PSU 1 status: online
	#	- PSU 2 status: online
	# ...

=head3 AC_failed

Returns the alternating current failure status of the specified PSU.

=head3 DC_failed

Returns the direct current failure status of the specified PSU.

=head3 FRU_identity

Returns the Field Replacable Unit (FRU) identity of the specified PSU. 

=head3 FRU_part_number

Returns the Field Replacable Unit part number of the specified PSU.

=head3 PSU_id

Returns the PSU ID.

=head3 enclosure_id

Returns the enclosure ID of the enclosure in which the PSU resides.

=head3 error_sequence_number

Returns the last error sequence number of the PSU (if present).

=head3 fan_failed

Returns the fan failure condition status.

=head3 firmware_level_1

Returns the firmware level 1 identifier.

=head3 firmware_level_2

Returns the firmware level 2 identifier.

=head3 redundant

Returns the redundancy status of the PSU.

=head3 status

Returns the operational status of the PSU

=cut

