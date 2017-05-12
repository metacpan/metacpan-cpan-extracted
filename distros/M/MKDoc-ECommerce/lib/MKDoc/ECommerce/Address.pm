# -------------------------------------------------------------------------------------
# MKDoc::ECommerce::Address
# -------------------------------------------------------------------------------------
# Author : Jean-Michel Hiver <jhiver@mkdoc.com>.
# Copyright : (c) MKDoc Holdings Ltd, 2003
#
# This object represents a postal address.
# -------------------------------------------------------------------------------------
package MKDoc::ECommerce::Address;
use warnings;
use strict;
use MKDoc::Core::Error;
use MKDoc::XML::Encode;
use Geography::Countries qw();


##
# $class->new (
#     first_name   => $first_name,
#     last_name    => $last_name,
#     company_name => $company_name,
#     email        => $email,
#     email_check  => $email_check,
#     address1     => $address_first_line,
#     address2     => $address_second_line,
#     city         => $city,
#     zip          => $zip,
#     country      => $country,
#     phone        => $phone_number
# );
##
sub new
{
    my $class = shift;
    my $self  = bless { @_ }, $class;
    return $self if ($self->validate());
    return;
}


sub first_name
{
    my $self = shift;
    return $self->{first_name};
}


sub last_name
{
    my $self = shift;
    return $self->{last_name};
}


sub company_name
{
    my $self = shift;
    return $self->{company_name};
}


sub email
{
    my $self = shift;
    return $self->{email};
}


sub address1
{
    my $self = shift;
    return $self->{address1};
}


sub address2
{
    my $self = shift;
    return $self->{address2};
}


sub city
{
    my $self = shift;
    return $self->{city};
}


sub country
{
    my $self = shift;
    return $self->{country};
}


sub country_iso
{
    my $self = shift;
    my @res  = Geography::Countries::country ($self->country());
    return $res[0];
}


sub state
{
    my $self = shift;
    return $self->{state};
}


sub zip
{
    my $self = shift;
    return $self->{zip};
}


sub phone
{
    my $self = shift;
    return $self->{phone};
}


##
# $self->validate();
# ------------------
# Returns TRUE if this address object validates, FALSE otherwise.
# Triggers MKDoc::Ouch soft errors.
##
sub validate
{
    my $self = shift;
    
    return $self->validate_first_name()    &
	   $self->validate_last_name()     &
	   $self->validate_email()         &
	   $self->validate_email_check()   &
	   $self->validate_address()       &
	   $self->validate_city()          &
	   $self->validate_state()         &
	   $self->validate_zip();
}


sub validate_first_name
{
    my $self = shift;
    $self->{first_name} || do {
	new MKDoc::Ouch 'ecommerce/address/first_name_empty';
	return 0;
    };
    
    return 1;
}


sub validate_last_name
{
    my $self = shift;
    $self->{last_name} || do {
	new MKDoc::Ouch 'ecommerce/address/last_name_empty';
	return 0;
    };
    
    return 1;
}


sub validate_email
{
    my $self = shift;
    $self->{email} || do {
	new MKDoc::Ouch 'ecommerce/address/email_empty';
	return 0;
    };
    
    return 1;
}


sub validate_address
{
    my $self = shift;
    $self->{address1} || do {
	new MKDoc::Ouch 'ecommerce/address/address_empty';
	return 0;
    };
    
    return 1;
}


sub validate_city
{
    my $self = shift;
    $self->{city} || do {
	new MKDoc::Ouch 'ecommerce/address/city_empty';
	return 0;
    };
    
    return 1;
}


sub validate_state
{
    my $self = shift;
    $self->{state} || do {
	new MKDoc::Ouch 'ecommerce/address/state_empty';
	return 0;
    };
    
    return 1;
}


sub validate_zip
{
    my $self = shift;
    $self->{zip} || do {
	new MKDoc::Ouch 'ecommerce/address/zip_empty';
	return 0;
    };
    
    return 1;
}


sub validate_email_check
{
    my $self = shift;
    
    # dangerous?
    not defined $self->{email_check} and
	not defined $self->{email}   and
	return 1;
    
    my $email_check = $self->{email_check} || '';
    $email_check eq $self->{email} || do {
	new MKDoc::Ouch 'ecommerce/address/email_mismatch';
	return 0;
    };
    
    return 1;
}


sub as_string
{
    my $self   = shift;
    my $string = '';
    
    $string .= $self->first_name() . " " . $self->last_name . "\n";
    $string .= $self->company_name() . "\n" if ($self->company_name());
    $string .= $self->address1() . "\n" if ($self->address1());
    $string .= $self->address2() . "\n" if ($self->address2());
    $string .= $self->city() . " " . $self->state() . "\n";
    $string .= $self->zip() . "\n";
    $string .= $self->country();
    
    return $string;
}


# address_combined_encoded
sub combined_encoded
{
    my $self   = shift;
    
    my $string = MKDoc::XML::Encode->process ($self->address1());
    $string   .= '&#10;';
    $string   .= MKDoc::XML::Encode->process ( $self->address2() ) if ($self->address2());
    $string   .= '&#10;' if ($self->address2());
    $string   .= MKDoc::XML::Encode->process ( $self->city() );
    
    return $string;
}


1;


__END__
