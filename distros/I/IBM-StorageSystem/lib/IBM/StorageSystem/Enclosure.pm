package IBM::StorageSystem::Enclosure;

use strict;
use warnings;

use IBM::StorageSystem::Enclosure::Canister;
use IBM::StorageSystem::Enclosure::Battery;
use IBM::StorageSystem::Enclosure::Slot;
use IBM::StorageSystem::Enclosure::PSU;
use Scalar::Util qw(weaken);
use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(FRU_identity FRU_part_number IO_group_id IO_group_name drive_slots 
error_sequence_number fault_LED firmware_level_1 firmware_level_2 id identify_LED 
machine_part_number managed online_PSUs online_canisters product_MTM serial_number 
status total_PSUs total_canisters type);

our $OBJ = {
		psu => {
			bcmd	=> 'lsenclosurepsu -nohdr -delim :',
			cmd	=> 'lsenclosurepsu -psu',
			id	=> 'PSU_id',
			class	=> 'IBM::StorageSystem::Enclosure::PSU',
			type	=> 'psu',
		},
		battery => {
			bcmd	=> 'lsenclosurebattery -nohdr -delim :',
			cmd	=> 'lsenclosurebattery -battery',
			id	=> 'battery_id',
			class	=> 'IBM::StorageSystem::Enclosure::Battery',
			type	=> 'battery'
		},
		slot => {
			bcmd	=> 'lsenclosureslot -nohdr -delim :',
			cmd	=> 'lsenclosureslot -slot',
			id	=> 'slot_id',
			class	=> 'IBM::StorageSystem::Enclosure::Slot',
			type	=> 'slot'
		},
		canister => {
			bcmd	=> 'lsenclosurecanister -nohdr -delim :',
			cmd	=> 'lsenclosurecanister -canister',
			id	=> 'canister_id',
			class	=> 'IBM::StorageSystem::Enclosure::Canister',
			type	=> 'slot'
		},
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
        $args{id} or croak 'Constructor failed: mandatory id argument not supplied';
	weaken( $self->{__ibm} = $ibm );

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

			my @objects = map { ( split /:/, $_ )[1] . " $self->{id}" } 
				      split /\n/, $self->{__ibm}->__cmd( $OBJ->{$obj}->{bcmd} ." $self->{id}" );

			my %a = ( objects => [@objects], cmd => $OBJ->{$obj}->{cmd}, class => $OBJ->{$obj}->{class}, nocache => 1 );

			@objects = $self->{__ibm}->__get_ml_objects( %a );

			foreach my $object ( @objects ) { $self->{ $OBJ->{$obj}->{type} }->{ $object->{ $OBJ->{$obj}->{id} } } = $object }

			return ( defined $id ? $self->{ $OBJ->{$obj}->{type} }->{$id} : @objects )
		}
	}
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Enclosure - Class for operations with a IBM Storwize enclosure

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem is a utility class for operation with an IBM Storwize enclosure.

	use IBM::StorageSystem;
	
	my $ibm = IBM::StorageSystem->new(	user		=> 'admin',
					host		=> 'my-v7000',
					key_path	=> '/path/to/my/.ssh/private_key'
				) or die "Couldn't create object! $!\n";
	
	# Print the status of each enclosure in our system.
	foreach my $enclosure ( $ibm->get_enclosures ) {
		print "Enclosure ", $enclosure->id, " status: ", $enclosure->status, "\n"
	}

	# Print the status of a specific enclosure
	print "Enclosure two status is " . $ibm->enclosure(2)->status . "\n";

	# Get all PSUs in an enclosure as L<IBM::StorageSystem::Enclosure::PSU> objects.
	my @psus = $ibm->enclosure(1)->psus;

	# Plus much more

=head1 METHODS

=head3 new 

Constructor method - note that under normal circumstances you shouldn't need to explicitly call 
this method - rather a L<IBM::StorageSystem::Enclosure> object is created for you via calls to methods
in other classes like B<get_enclosure> in L<IBM::StorageSystem>.

=head3 psu( $id )

	# Get the first PSU of the first enclosure and print the redundancy status
	my $enclosure = $ibm->enclosure(1);
	my $psu = $enclosure->psu(1);
	print $psu->redundant;

	# Alternately
	print $ibm->enclosure(1)->psu(1)->redundant;

Returns the PSU as specified by the value of the id parameter as a L<IBM::StorageSystem::Enclosure::PSU>
object.  

Note that this method implements object caching when possible - please refer to the B<Caching>
section in the L<IBM::StorageSystem> documentation for further detail.

=head3 get_psu( $id )

	my $psu = $enclosure->get_psu(2);

Returns the PSU as specified by the value of the id parameter as a L<IBM::StorageSystem::Enclosure::PSU>
object.

=head3 get_psus

	my @psus = $enclosure->get_psus;

Returns an all PSUs in the specified enclosure as an array of L<IBM::StorageSystem::Enclosure::PSU> objects.

=head3 battery( $id )

	# Print the percentage charged status of the first battery in the second enclosure
	print $ibm->enclosure(2)->battery(1)->percent_charged;

Returns the enclosure battery as specified by the value of the given id parameter as a 
L<IBM::StorageSystem::Enclosure::Battery> object.

Note that this method implements object caching when possible - please refer to the B<Caching>
section in the L<IBM::StorageSystem> documentation for further detail.

=head3 get_battery( $id )

	# Get the first battery of the first enclosure.
	my $battery = $ibm->enclosure(1)->get_battery(1);

Returns the enclosure battery as specified by the value of the id parameter as a 
L<IBM::StorageSystem::Enclosure::Battery> object.

=head3 get_batterys

	# Get all batteries for an enclosure object.
	my @batterys = $enclosure->get_batterys;

Returns a list of L<IBM::StorageSystem::Enclosure::Battery> objects for the specified enclosure.

=head3 slot( $id )

	# Check the SAS port and LED fault states of slot 1.
	my $slot = $ibm->enclosure(1)->slot(1);

	if ( ( $slot->port_1_status ne 'online' or $slot->port_2_status ne 'online' ) 
		or $slot->fault_LED ne 'off' ) { jump_up_and_down() }

Returns a L<IBM::StorageSystem::Enclosure::Slot> object for the slot specified by the id parameter.

Note that this method implements object caching when possible - please refer to the B<Caching>
section in the L<IBM::StorageSystem> documentation for further detail.

=head3 get_slot( $id )

Returns a L<BM::StorageSystem::Enclosure::Slot> object for the slot specified by the id parameter.

=head3 get_slots

	# Print the drive ID for each slot.
	map { print "Slot ", $_->slot_id, " drive ID: ", $_->drive_id, "\n" } $enclosure->get_slots;

Returns a list of L<IBM::StorageSystem::Enclosure::Slot> objects for the specified enclosure.

=head3 canister( $id )

	# Get the first canister of this enclosure
	my $canister = $enclosure->canister(1);

	# Check and alert the canister temperature
	SMS_NOC( "Enclosure ${ $enclosure->id } canister ${ canister->id } ".
		 "temperature ${ $canister->temperature }C" ) if ($canister->temperature > 45);

Returns the canister for this enclosure as specified by the id parameter as an 
L<IBM::StorageSystem::Enclosure::Canister> object.

Note that this method implements object caching when possible - please refer to the B<Caching>
section in the L<IBM::StorageSystem> documentation for further detail.

=head3 get_canister( $id )

Returns the canister for this enclosure as specified by the id parameter as an 
L<IBM::StorageSystem::Enclosure::Canister> object.

=head3 get_canisters

	my @canisters = $enclosure->get_canisters;

Returns a list of all present canisters in this enclosure as L<IBM::StorageSystem::Enclosure::Canister> 
objects.

=head3 FRU_identity

Returns the Field Replacable Unit (FRU) identity of the enclosure.

=head3 FRU_part_number

Returns the Field Replacable Unit part number of the enclosure.

=head3 IO_group_id

Returns the IO group ID for this enclosure.

=head3 IO_group_name

Returns the IO group name for this enclosure.

=head3 drive_slots

Returns the number of drive slots present in this enclosure.

=head3 error_sequence_number

Returns the error sequence number (if any) of the most recently logged error condition.

=head3 fault_LED

Returns the fault LED state.

=head3 firmware_level_1

Returns the firmware level 1 code.

=head3 firmware_level_2

Returns the firmware level 2 code.

=head3 id

Returns the enclosure ID.

=head3 identify_LED

Returns the identity LED state.

=head3 machine_part_number

Returns the machine part number of the enclosure (if present).

=head3 managed

Returns the managed status of the enclosure.

=head3 online_PSUs

Returns the number of online PSUs present in this enclosure.

=head3 online_canisters

Returns the number of online canisters present in this enclosure.

=head3 product_MTM

Returns the product Manufacturing Type Model code for this enclosure.

=head3 serial_number

Returns the serial number of this enclosure.

=head3 status

Returns the system status of this enclosure.

=head3 total_PSUs

Returns the total number of PSUs present in this enclosure.

=head3 total_canisters

Returns the total number of canisters present in this enclosure.

=head3 type

Returns the enclosure operational type.

=cut

