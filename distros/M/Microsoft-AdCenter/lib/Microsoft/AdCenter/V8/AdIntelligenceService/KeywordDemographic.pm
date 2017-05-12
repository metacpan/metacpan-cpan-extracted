package Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographic;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Microsoft::AdCenter::ComplexType/;

=head1 NAME

Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographic - Represents "KeywordDemographic" in Microsoft AdCenter Ad Intelligence Service.

=cut

sub _type_name {
    return 'KeywordDemographic';
}

sub _namespace_uri {
    return 'http://schemas.datacontract.org/2004/07/Microsoft.AdCenter.Advertiser.CampaignManagement.Api.DataContracts';
}

our @_attributes = (qw/
    Age18_24
    Age25_34
    Age35_49
    Age50_64
    Age65Plus
    AgeUnknown
    Female
    GenderUnknown
    Male
/);

sub _attributes {
    my $self = shift;
    return ($self->SUPER::_attributes, @_attributes);
}

our %_attribute_type = (
    Age18_24 => 'double',
    Age25_34 => 'double',
    Age35_49 => 'double',
    Age50_64 => 'double',
    Age65Plus => 'double',
    AgeUnknown => 'double',
    Female => 'double',
    GenderUnknown => 'double',
    Male => 'double',
);

sub _attribute_type {
    my ($self, $attribute) = @_;
    if (exists $_attribute_type{$attribute}) {
        return $_attribute_type{$attribute};
    }
    return $self->SUPER::_attribute_type($attribute);
}

our %_attribute_min_occurs = (
    Age18_24 => 0,
    Age25_34 => 0,
    Age35_49 => 0,
    Age50_64 => 0,
    Age65Plus => 0,
    AgeUnknown => 0,
    Female => 0,
    GenderUnknown => 0,
    Male => 0,
);

sub _attribute_min_occurs {
    my ($self, $attribute) = @_;
    if (exists $_attribute_min_occurs{$attribute}) {
        return $_attribute_min_occurs{$attribute};
    }
    return $self->SUPER::_attribute_min_occurs($attribute);
}

__PACKAGE__->mk_accessors(@_attributes);

1;

=head1 SYNOPSIS

See L<http://msdn.microsoft.com/en-us/library/ee730327.aspx> for documentation of the various data objects.

=cut

=head1 METHODS

=head2 new

Creates a new instance

=head2 Age18_24

Gets/sets Age18_24 (double)

=head2 Age25_34

Gets/sets Age25_34 (double)

=head2 Age35_49

Gets/sets Age35_49 (double)

=head2 Age50_64

Gets/sets Age50_64 (double)

=head2 Age65Plus

Gets/sets Age65Plus (double)

=head2 AgeUnknown

Gets/sets AgeUnknown (double)

=head2 Female

Gets/sets Female (double)

=head2 GenderUnknown

Gets/sets GenderUnknown (double)

=head2 Male

Gets/sets Male (double)

=cut

