package HTML::FormHandler::Widget::Field::Span;
# ABSTRACT: button field rendering widget
$HTML::FormHandler::Widget::Field::Span::VERSION = '0.40068';

use Moose::Role;
use HTML::FormHandler::Render::Util ('process_attrs');
use namespace::autoclean;

sub render_element {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $output = '<span';
    $output .= ' id="' . $self->id . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= '>';
    $output .= $self->value;
    $output .= '</span>';
    return $output;
}

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    die "No result for form field '" . $self->full_name . "'. Field may be inactive." unless $result;
    my $output = $self->render_element( $result );
    return $self->wrap_field( $result, $output );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Span - button field rendering widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Renders the NonEditable pseudo-field as a span.

   <span id="my_field" class="test">The Field Value</span>

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
