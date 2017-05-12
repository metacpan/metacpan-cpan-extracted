package Marketplace::Ebay::Order::Address;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
use namespace::clean;

=head1 NAME

Marketplace::Ebay::Order::Address

=head1 DESCRIPTION

Class to handle the xml structures representing an address.

This modules doesn't do much, it just provides an uniform iterface
with other Marketplace modules.

=cut

=head1 ACCESSORS

=head2 CONSTRUCTOR ARGUMENTS (from xml)

=over 4

=item * Name

=item * Street1

=item * Street2

=item * CityName

=item * PostalCode

=item * StateOrProvince

=item * Country

=item * CountryName

=item * Phone

=item * AddressOwner

=item * ExternalAddressID

=item * AddressID

=back

=cut

has Name => (is => 'ro', isa => Str);
has Street1 => (is => 'ro', isa => Str);
has Street2 => (is => 'ro', isa => Str);
has CityName => (is => 'ro', isa => Str);
has PostalCode => (is => 'ro', isa => Str);
has StateOrProvince => (is => 'ro', isa => Str);
has Country => (is => 'ro', isa => Str);
has CountryName => (is => 'ro', isa => Str);
has Phone => (is => 'ro', isa => Str);
has AddressOwner => (is => 'ro', isa => Str);
has ExternalAddressID => (is => 'ro', isa => Str);
has AddressID => (is => 'ro', isa => Str);

=head2 ALIASES

=over 4

=item address1 (Street1)

=item address2 (Street2)

=item name (Name)

=item city (CityName)

=item state (StateOrProvince)

=item zip (PostalCode)

=item phone (Phone)

Return the empty string if "Invalid Request" is found.

=item country (Country)

=back

=cut

sub address1 {
    return shift->Street1;
}

sub address2 {
    return shift->Street2;
}

sub name {
    return shift->Name;
}

sub city {
    return shift->CityName;
}

sub state {
    return shift->StateOrProvince;
}

sub zip {
    return shift->PostalCode;
}

sub phone {
    my $self = shift;
    my $phone = $self->Phone;
    if ($phone and $phone eq 'Invalid Request') {
        return '';
    }
    else {
        return $phone;
    }
}

sub country {
    return shift->Country;
}

1;
