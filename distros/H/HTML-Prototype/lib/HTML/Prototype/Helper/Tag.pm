package HTML::Prototype::Helper::Tag;

use strict;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(
    qw/object object_name method_name template_object local_binding auto_index/
);
use vars qw/$USE_ASXML_FOR_TAG/;
$USE_ASXML_FOR_TAG = 0;

=head1 NAME

HTML::Prototype::Helper::Tag - Defines a tag object needed by HTML::Prototype

=head1 SYNOPSIS

	use HTML::Prototype::Helper;

=head1 DESCRIPTION

Defines a tag object needed by HTML::Prototype

=head2 REMARKS

Until version 1.43, the internal function I<$self->_tag> used I<$tag->as_XML>
as its return value. By now, it will use I<$tag->as_HTML( $entities )> to
invokee I<HTML::Entities::encode_entities>. This behaviour can be overridden
by setting I<$HTML::Prototype::Helper::Tag::USE_ASXML_FOR_TAG> to 1.

=head2 METHODS

=over 4

=item HTML::Prototype::Helper::Tag->new( $object_name, $method_name, $template_object, $local_binding, $object )

=cut

sub new {
    my ( $class, $object_name, $method_name, $template_object, $local_binding,
        $object )
      = @_;

    my $self = $class->SUPER::new();

    $self->object($object);
    $self->object_name($object_name);
    $self->method_name($method_name);
    $self->template_object($template_object);
    $self->local_binding($local_binding);

    if ( $object_name =~ s/\[\]$// ) {
        $self->auto_index( $self->template_object->instance_variable_get($`) );
        $self->object_name($object_name);
    }

    return $self;
}

=item $tag->object_name( [$object_name] )

=item $tag->method_name( [$method_name] )

=item $tag->template_object( [$template_object] )

=item $tag->local_binding( [$local_binding] )

=item $tag->object( [$object] )

=cut

sub object {
    my $self = shift;
    @_ = ( $self->template_object->instance_variable_get( $self->object_name ) )
      unless @_;
    return $self->_object_accessor(@_);
}

=item $tag->value( )

=cut

sub value {
    my $self    = shift;
    my $coderef =
      $self->object ? $self->object->can( $self->method_name ) : undef;
    return $coderef ? $self->object->$coderef() : '';
}

=item $tag->value_before_type_cast( )

=cut

sub value_before_type_cast {
    my $self = shift;

    my $value = '';
    if ( defined $self->object ) {
        my $coderef =
             $self->object->can( $self->method_name . '_before_type_cast' )
          || $self->object->can( $self->method_name );
        $value = $self->object->$coderef() if $coderef;
    }

    return $value;
}

=item $tag->to_input_field_tag( $field_type, \%options )

=cut

sub to_input_field_tag {
    my ( $self, $field_type, $options ) = @_;

    $options ||= {};
    $options->{size} ||= $options->{maxlength} || 30;
    delete $options->{size} if 'hidden' eq lc $field_type;
    $options->{type} = $field_type;
    $options->{value} ||= $self->value_before_type_cast()
      unless 'file' eq lc $field_type;

    $self->_add_default_name_and_id($options);
    return $self->_tag( "input", $options );
}

=item $tag->to_content_tag( $tag_name, $value, \%options )

=cut

sub to_content_tag {
    my ( $self, $tag_name, $options ) = @_;

    return $self->_content_tag( $tag_name, $self->value(), $options || {} );
}

sub _add_default_name_and_id {
    my ( $self, $options ) = @_;

    $options ||= {};

    my $index;
    if (   ( $index = delete $options->{index} )
        || ( $index = $self->auto_index ) )
    {
        $options->{name} ||= $self->_tag_name_with_index($index);
        $options->{id}   ||= $self->_tag_id_with_index($index);
    }
    else {
        $options->{name} ||= $self->_tag_name;
        $options->{id}   ||= $self->_tag_id;
    }
}

sub _tag_name {
    my $self = shift;

    return $self->object_name . '[' . $self->method_name . ']';
}

sub _tag_name_with_index {
    my ( $self, $index ) = @_;

    return $self->object_name . '[' . $index . '][' . $self->method_name . ']';
}

sub _tag_id {
    my $self = shift;

    return $self->object_name . '_' . $self->method_name;
}

sub _tag_id_with_index {
    my ( $self, $index ) = @_;

    return $self->object_name . '_' . $index . '_' . $self->method_name;
}

sub _tag {
    my ( $self, $name, $options, $starttag ) = @_;
    $starttag ||= 0;
    $options  ||= {};
    my $entities =
      defined $options->{entities}
      ? delete $options->{entities}
      : '<>&';
    my $tag = HTML::Element->new( $name, %$options );
    if ($starttag) {
        return $tag->starttag($entities);
    }
    elsif ($USE_ASXML_FOR_TAG) {
        return $tag->as_XML;
    }
    else {
        $tag->as_HTML($entities);
    }
}

sub _content_tag {
    my ( $self, $name, $content, $html_options ) = @_;
    $html_options ||= {};
    my $entities =
      defined $html_options->{entities}
      ? delete $html_options->{entities}
      : '<>&';
    my $tag = HTML::Element->new( $name, %$html_options );
    $tag->push_content( ref $content eq 'ARRAY' ? @{$content} : $content );
    return $tag->as_HTML($entities);
}

=back

=head1 SEE ALSO

L<HTML::Prototype>, L<http://prototype.conio.net/>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

Built around Prototype by Sam Stephenson.
Much code is ported from Ruby on Rails javascript helpers.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
