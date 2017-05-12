package Marketplace::Rakuten::Order::Address;

use Moo;
use MooX::Types::MooseLike::Base qw(Str);
use namespace::clean;

=head1 NAME

Marketplace::Rakuten::Order::Address

=head1 DESCRIPTION

Class to handle the xml structures representing an address.

This modules doesn't do much, it just provides an uniform iterface
with other Marketplace modules.

=head1 ACCESSORS

=head2 CONSTRUCTOR ARGUMENTS (from xml)

=over 4

=item * client_id

=item * gender

=item * first_name

=item * last_name

=item * company

=item * street

=item * street_no

=item * address_add

=item * zip_code

=item * city

=item * country

=item * email

=item * phone

=back

=cut

has client_id => (is => 'ro', isa => Str);
has gender => (is => 'ro', isa => Str);
has first_name => (is => 'ro', isa => Str);
has last_name => (is => 'ro', isa => Str);
has company => (is => 'ro', isa => Str);
has street => (is => 'ro', isa => Str);
has street_no => (is => 'ro', isa => Str);
has address_add => (is => 'ro', isa => Str);
has zip_code => (is => 'ro', isa => Str);
has city => (is => 'ro', isa => Str);
has country => (is => 'ro', isa => Str);
has email => (is => 'ro', isa => Str);
has phone => (is => 'ro', isa => Str);

=head2 ALIASES

=over 4

=item address1

Concatenation of street and street_no

=item address2 (address_add)

=item name 

Concatenation of company, first_name, last_name

=item state

Always return the empty string, Rakuten doesn't give it.

=item zip (zip_code)

=back

=cut

sub address1 {
    my $self = shift;
    return $self->street . ' ' . $self->street_no;
}

sub address2 {
    my $self = shift;
    return $self->address_add;
}

sub name {
    my $self = shift;
    my $out = '';
    if ($self->company) {
        $out = $self->company . ' ';
    }
    return $out . $self->first_name . ' ' . $self->last_name;
}

sub state {
    # not provided, apparently
    return '';
}

sub zip {
    return shift->zip_code;
}



1;
