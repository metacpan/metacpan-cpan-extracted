use utf8;
package Interchange6::Schema::Base::Attribute;

=head1 NAME

Interchange6::Schema::Base::Attribute

=cut

use strict;
use warnings;

=head1 DESCRIPTION

The Attribute base class is consumed by classes with attribute
relationships like L<Interchange6::Schema::Result::User>,
L<Interchange6::Schema::Result::Navigation>
and L<Interchange6::Schema::Result::Product>.

=over 4

=item B<Assumptions>

This module assumes that your using standardized class naming.

example: User in this example is the $base class so UserAttribute, 
UserAttributeValue class naming would be used.  These would
also use user_attributes_id and user_attributes_values_id as primary
keys.  In general follow the example classes listed in description.

=back

=cut

=head1 SYNOPSIS

    $navigation_object->add_attribute('meta_title','My very seductive title here!');

=head1 METHODS

=head2 add_attribute

Add attribute.

    $base->add_attribute('hair_color', 'blond');

Where 'hair_color' is Attribute and 'blond' is AttributeValue

=cut

sub add_attribute {
    my ($self, $attr, $attr_value) = @_;
    my $base = $self->result_source->source_name;

    # find or create attributes
    my ($attribute, $attribute_value) = $self->find_or_create_attribute($attr, $attr_value);

    # create base_attribute object
    my $base_attribute = $self->find_or_create_related(lc($base) . '_attributes',
                                                       {attributes_id => $attribute->id});
    # create base_attribute_value
    $base_attribute->create_related(lc($base) . '_attribute_values',
                                    {attribute_values_id => $attribute_value->id});

    return $self;
}

=head2 update_attribute_value

Update base attribute value

    $base->update_attribute('hair_color', 'brown');

=cut

sub update_attribute_value {
    my ($self, $attr, $attr_value) = @_;
    my $base = $self->result_source->source_name;

    my ($attribute, $attribute_value) = $self->find_or_create_attribute($attr, $attr_value);

    my (undef, $base_attribute_value) = $self->find_base_attribute_value($attribute, $base);

    $base_attribute_value->update({attribute_values_id => $attribute_value->id});

    return $self;
}

=head2 delete_attribute

Delete $base attribute

    $base->delete_attribute('hair_color', 'purple');

=cut

sub delete_attribute {
    my ($self, $attr, $attr_value) = @_;
    my $base = $self->result_source->source_name;

    my ($attribute) = $self->find_or_create_attribute($attr, $attr_value);

    my ($base_attribute, $base_attribute_value) = $self->find_base_attribute_value($attribute, $base);

    #delete
    $base_attribute_value->delete;
    $base_attribute->delete;

    return $self;
}

=head2 search_attributes

Returns attributes resultset for a $base object

    $rs = $base->search_attributes;

You can pass conditions and attributes to the search like for
any L<DBIx::Class::ResultSet>, e.g.:

    $rs = $base->search_attributes(
        undef, { order_by => 'priority desc' });

=cut

sub search_attributes {
    my ($self, $condition, $search_atts) = @_;

    my $base = $self->result_source->source_name;

    my $base_attributes = $self->search_related(lc($base) . '_attributes');

    my $attributes = $base_attributes->search_related('attribute',
                                                  $condition, $search_atts);

    return $attributes;
}

=head2 find_attribute_value

Finds the attribute value for the current object or a defined object value.
If $object is passed the entire attribute_value object will be returned. $args can
accept both scalar and hash inputs.

    $base->find_attribute_value({name => $attr_name, priority => $attr_priority}, {object => 1});

=cut

sub find_attribute_value {
    my ($self, $args, $object) = @_;
    my $base = $self->result_source->source_name;
    my $lc_base = lc($base);

    # attribute must be set
    unless ($args) {
       die "find_attribute_value input requires at least a valid attribute value";
    };

    my %attr = ref($args) eq 'HASH' ? %{$args} : (name => $args);

    my $attribute = $self->result_source->schema->resultset('Attribute')->find( \%attr );

    unless ($attribute) {
        return undef;
    }

    # find records
    my $base_attribute = $self->find_related($lc_base . '_attributes',
                                            {attributes_id => $attribute->id});

    unless ($base_attribute) {
        return undef;
    }

    my $base_attribute_value = $base_attribute->find_related($lc_base .'_attribute_values',
                                            {$lc_base . '_attributes_id' => $base_attribute->id});
    unless ($base_attribute_value) {
        return undef;
    }

    my $attribute_value = $base_attribute_value->find_related('attribute_value',
                                            {lc($base) .'_attribute_values_id' => $base_attribute_value->id});
    if ($object) {
        return $attribute_value;
    }
    else {
        return $attribute_value->value;
    }
};

=head2 search_attribute_values

=over 4

=item Arguments: L<$cond|DBIx::Class::SQLMaker> | undef, L<\%attrs|DBIx::Class::ResultSet/ATTRIBUTES> | undef, L<\%av_attrs|DBIx::Class::ResultSet/ATTRIBUTES>

Where $cond and %attrs are passed to the Attribute search and %av_attrs is passed to the AttributeValue search.

=item Return Value: Array (or arrayref in scalar context) of attributes and values for for the $base object input.

=back

    my $product = $schema->resultset('Product')->find({ sku = '123' });
    my $av = $product->search_attribute_values(
        undef, { order_by => 'priority' }, { order_by => 'priority' });

=cut

sub search_attribute_values {
    my ($self, $condition, $search_atts, $av_search_atts) = @_;
    my $base = $self->result_source->source_name; 
    my (%base_data, %attr_values, @data);

    my $base_attributes = $self->search_related(lc($base) . '_attributes');

    my $attributes_rs = $base_attributes->search_related('attribute',
                                                  $condition, $search_atts);

    while (my $attribute = $attributes_rs->next) {
        my @values;
        my $attribute_value_rs = $attribute->search_related('attribute_values',
            undef, $av_search_atts);
        while (my $attribute_value = $attribute_value_rs->next) {

            # get key value pairs
            my %attr_values = $attribute_value->get_columns;
            push( @values, { %attr_values });
        }
        my %base_data = $attribute->get_columns;

        # populate values
        $base_data{attribute_values} = \@values;
        push( @data, { %base_data });
    }
    return wantarray ? @data : \@data;
};

=head2 find_or_create_attribute

Find or create attribute and attribute_value.

=cut

sub find_or_create_attribute {
    my ( $self, $attr, $value ) = @_;

    unless ( defined($attr) && defined($value) ) {
        die "Both attribute and attribute value are required for find_or_create_attribute";
    }

    # check if $attr is a HASH if not set as name
    my %attr = ref($attr) eq 'HASH' ? %{$attr} : (name => $attr);

    # check if $value is a HASH if not set as value
    my %attr_value = ref($value) eq 'HASH' ? %{$value} : (value => $value);

    my $attribute = $self->result_source->schema->resultset('Attribute')->find_or_create( %attr );

    # create attribute_values
    my $attribute_value = $attribute->find_or_create_related('attribute_values', \%attr_value );

    return ($attribute, $attribute_value);
};

=head2 find_base_attribute_value

From a $base->attribute input $base_attribute, $base_attribute_value is returned.

=cut

sub find_base_attribute_value {
    my ($self, $attribute, $base) = @_;

    unless($base) {
        die "Missing base name for find_base_attribute_value";
    }

    unless($attribute) {
        die "Missing attribute object for find_base_attribute_value";
    }

    my $lc_base = lc($base);

    my $base_attribute = $self->find_related($lc_base . '_attributes',
                                            {attributes_id => $attribute->id});

    my $base_attribute_value = $base_attribute->find_related($lc_base . '_attribute_values',
                                            {$lc_base . '_attributes_id' => $base_attribute->id});

    return ($base_attribute, $base_attribute_value);
}


1;
