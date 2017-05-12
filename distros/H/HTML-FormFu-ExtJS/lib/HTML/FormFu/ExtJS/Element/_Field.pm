#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package HTML::FormFu::ExtJS::Element::_Field;
BEGIN {
  $HTML::FormFu::ExtJS::Element::_Field::VERSION = '0.090';
}

use strict;
use warnings;
use utf8;

use HTML::FormFu::Util qw(
  xml_escape
);
use HTML::FormFu::ExtJS::Util qw(
  _camel_case
  _css_case
);

sub render {
    my $class  = shift;
    my $self   = shift;
    my $parent = $self->can("_get_attributes") ? $self : $self->form;
    my $value  = $self->default;
    map { $value = $_->process($value) } @{ $self->get_deflators };

    return {
        fieldLabel => xml_escape( $self->label ),
        hideLabel  => $self->label ? \0 : \1,
        ( scalar $self->id )   ? ( id    => scalar $self->id )   : (),
        $self->nested_name     ? ( name  => $self->nested_name ) : (),
        defined $self->default ? ( value => $value )             : (),
        $parent->_get_attributes($self)
    };
}


sub record {
    my $class = shift;
    my $self  = shift;
    my %args  = %{ shift || {} };

    my $name = $self->nested_name;
    return {
        name    => _camel_case($name),
        mapping => $self->nested_name,
        type    => "string",
        %args
    };
}


sub column_model {
    my $class = shift;
    my $self  = shift;
    my %args  = %{ shift || {} };

    my $data_index = $self->nested_name;

    return {
        id        => _css_case($data_index),
        dataIndex => _camel_case($data_index),
        header    => scalar $self->label || scalar $self->name,
        $self->form->_get_attributes($self),
        %args
    };
}

1;

__END__
=pod

=head1 NAME

HTML::FormFu::ExtJS::Element::_Field

=head1 VERSION

version 0.090

=head2 record

C<record> returns a HashRef with contains all informations to create a record
field from this field element.

  $class->record( $element );

You can override the default values by passing an extra hashref.

  $class->record( $element, { mapping => 'myname', type => 'mytype' } );

=head2 column_model

C<column_model> returns a HashRef with contains all informations to create an
entry for a column model from this field element.

  $class->column_model( $element );

All attributes that were given to the element configuration are added to the
column model:

  - type: Text
    attrs:
      width: 150

You can override the defaults by passing a hashref:

  $class->column_model( $element, { dataIndex => 'myIndex' } );

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

