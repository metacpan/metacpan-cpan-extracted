package IBM::StorageSystem::Enclosure::Canister;

use strict;
use warnings;

use Carp qw(croak);

our @ATTR = qw(FRU_identity FRU_part_number SAS_port_1_status SAS_port_2_status SES_status WWNN canister_id enclosure_id error_sequence_number fault_LED firmware_level firmware_level_2 firmware_level_3 firmware_level_4 firmware_level_5 node_id node_name status temperature type);

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
        defined $args{canister_id} or croak 'Constructor failed: mandatory argument canister_id not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Enclosure::Canister - Class for operations with a IBM Storwize enclosure Canister

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Enclosure::Canister is a utility class for operations with a IBM Storwize enclosure Canister.

        use IBM::StorageSystem;

        my $ibm = IBM::StorageSystem->new(      
					user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                        ) or die "Couldn't create object! $!\n";

        # Print the WWNN of the first canister in the first enclosure.
        print $ibm->enclosure(1)->canister(1)->WWNN;

	# Print the temperatures of all canisters in this enclosure.
	map { print "Canister ", $_->canister_id, " temperature: ", $_->temperature } $enclosure->get_canisters;

=head3 FRU_identity

Returns the Field Replaceable Unit (FRU) identity number for the specified canister.

=head3 FRU_part_number

Returns the Field Replaceable Unit part number of the specified canister.

=head3 SAS_port_1_status

Returns the status of the first SAS port.

=head3 SAS_port_2_status

Returns the status of the second SAS port.

=head3 SES_status

Returns the SCSI Enclosure Services (SES) status of the specified canister.

=head3 WWNN

Returns the World Wide Node Name (WWNN) of the specified canister.

=head3 canister_id

Returns the numerical identifier of the specified canister.

=head3 enclosure_id

Returns the numerical identifier of the enclosure in which the specified
canister resides.

=head3 error_sequence_number

Returns the most recent error sequence number (if present).

=head3 fault_LED

Returns the state of the canister fault LED.

=head3 firmware_level

Returns the firmware level of the specified canister.

=head3 firmware_level_2

Returns the level 2 firmware code of the specified canister.

=head3 firmware_level_3

Returns the level 3 firmware code of the specified canister.

=head3 firmware_level_4

Returns the level 4 firmware code of the specified canister.

=head3 firmware_level_5

Returns the level 5 firmware code of the specified canister.

=head3 node_id

Returns the numerical node identifier of node in which the
specified canister resides.

=head3 node_name

Returns the name of the node in which this canister resides.

=head3 status

Returns the operational status of specified canister.

=head3 temperature

Returns the temperature in degrees Celcius of the specified canister.

=head3 type

Returns the specified canister type.

=cut

