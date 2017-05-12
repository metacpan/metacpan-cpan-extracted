package IBM::StorageSystem::Enclosure::Battery;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
our @ATTR = qw(FRU_identity FRU_part_number battery_id charging_status enclosure_id end_of_life_warning error_sequence_number firmware_level percent_charged recondition_needed status);

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
        defined $args{battery_id} or croak 'Constructor failed: mandatory argument battery_id not supplied';

        foreach my $attr ( @ATTR ) { $self->{$attr} = $args{$attr} }

        return $self
}

1;

__END__

=pod

=head1 NAME

IBM::StorageSystem::Enclosure::Battery - Class for operations with a IBM Storwize enclosure battery

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

IBM::StorageSystem::Enclosure::Battery is a utility class for operations with a IBM Storwize 
enclosure battery.

        use IBM::StorageSystem;
        
        my $ibm = IBM::StorageSystem->new(      user            => 'admin',
                                        host            => 'my-v7000',
                                        key_path        => '/path/to/my/.ssh/private_key'
                                ) or die "Couldn't create object! $!\n";

	# Get a list of the batteries in enclosure two
	my @batteries = $ibm->enclosure(2)->get_batterys;

	# Print the percent charged status of each battery
	for my $battery ( @batteries ) {
		print "Battery " $battery->battery_id . " percent charged: " 
			. $_->percent_charged . "%\n"
	}

=head1 METHODS

=head3 FRU_identity

Returns the FRU (Field Replacable Unit) identity number of the battery.

=head3 FRU_part_number

Returns the FRU (Field Replacable Unit) part number of the battery.

=head3 battery_id

Returns the numerical identifier of this battery within the conext of the enclosure.

=head3 charging_status

Returns the charging status of the specified battery.

=head3 enclosure_id

Returns the enclosure ID of the specified battery.

=head3 end_of_life_warning

Returns the end of life warning of the specified battery.

=head3 error_sequence_number

Returns the error sequence number for the specified battery.

=head3 firmware_level

Returns the firmware level of the specified battery.

=head3 percent_charged

Returns the percent charged of the specified battery.

=head3 recondition_needed

Returns the recondition needed status of the specified battery.

=head3 status

Returns the operational status of the specified battery.

=cut

