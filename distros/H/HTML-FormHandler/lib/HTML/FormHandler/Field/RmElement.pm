package HTML::FormHandler::Field::RmElement;
# ABSTRACT: field to support repeatable javascript remove
$HTML::FormHandler::Field::RmElement::VERSION = '0.40068';
use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Display';
use HTML::FormHandler::Render::Util ('process_attrs');


has '+do_wrapper' => ( default => 1 );
has '+value'  => ( default => 'Remove' );

sub build_render_method {
    return sub {
        my ( $self, $result ) = @_;
        $result ||= $self->result;

        my $value = $self->html || $self->html_filter($self->_localize($self->value));
        my $attrs = $self->element_attributes($result);
        push @{$attrs->{class}}, ( 'rm_element', 'btn' );
        $attrs->{'data-rep-elem-id'} = $self->parent->id;
        $attrs->{id} = $self->id;
        my $attr_str = process_attrs($attrs);
        my $wrapper_tag = $self->get_tag('wrapper_tag') || 'div';
        my $output = qq{<$wrapper_tag$attr_str>$value</$wrapper_tag>};
        $output = $self->wrap_field($self->result, $output);
        return $output;
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::RmElement - field to support repeatable javascript remove

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

EXAMPLE field for rendering an RmElement field for
doing javascript removals of repeatable elements.

You probably want to make your own.

The main requirements are that the button have 1) the
'rm_element' class, 2) a 'data-rep-elem-id' attribute that
contains the id of the repeatable instance that you want
to remove (C<< $self->parent->id >>).

This field should be a subfield of the Repeatable, probably
either first or last.

=head1 NAME

HTML::FormHandler::Field::RmElement

=head1 ATTRIBUTES

    has_field 'rm_element' => ( type => 'RmElement',
        value => 'Remove',
    );

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
