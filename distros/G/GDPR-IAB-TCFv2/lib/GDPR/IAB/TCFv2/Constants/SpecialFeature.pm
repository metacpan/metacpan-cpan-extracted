package GDPR::IAB::TCFv2::Constants::SpecialFeature 0.530;
use v5.12;
use warnings;

require Exporter;
use parent qw<Exporter>;

use constant {

  # Short, established names -- supported indefinitely.
  Geolocation => 1,
  DeviceScan  => 2,

  # TCF v2.3 spec-aligned long-form aliases (Phase 3).
  UsePreciseGeolocationData                          => 1,
  ActivelyScanDeviceCharacteristicsForIdentification => 2,
};

use constant SpecialFeatureDescription => {
  Geolocation => "Use precise geolocation data",
  DeviceScan  => "Actively scan device characteristics for identification"
};

our @EXPORT_OK = qw<
  Geolocation
  DeviceScan
  UsePreciseGeolocationData
  ActivelyScanDeviceCharacteristicsForIdentification
  SpecialFeatureDescription
>;

our %EXPORT_TAGS = (all => \@EXPORT_OK);

1;

__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::Constants::SpecialFeature - TCF v2.3 special features

=head1 SYNOPSIS

    use warnings;
    
    use GDPR::IAB::TCFv2::Constants::SpecialFeature qw<:all>;

    use feature 'say';
    
    say "Special feature id is ", Geolocation, ", and it means " , SpecialFeatureDescription->{Geolocation};
    # Output:
    # Special feature id is 1, and it means Use precise geolocation data

=head1 CONSTANTS

All constants are integers.

To find the description of a given id you can use the hashref L</SpecialFeatureDescription>.

=head2  Geolocation

Special feature id 1: Use precise geolocation data

With your acceptance, your precise location (within a radius of less than 500 metres) may be used in support of the purposes explained in this notice.

=head2  DeviceScan

Special feature id 2: Actively scan device characteristics for identification

With your acceptance, certain characteristics specific to your device might be requested and used to distinguish it from other devices (such as the installed fonts or plugins, the resolution of your screen) in support of the purposes explained in this notice.

=head2 SpecialFeatureDescription

Returns a hashref with a mapping between all special feature ids and their description.

=head1 NAME ALIASES

Both special features are also exported under long-form aliases that mirror
the IAB Global Vendor List wording for TCF v2.3:

=over 4

=item *

C<Geolocation> — C<UsePreciseGeolocationData> (id 1)

=item *

C<DeviceScan> — C<ActivelyScanDeviceCharacteristicsForIdentification> (id 2)

=back

Both names resolve to the same integer and are interchangeable.
