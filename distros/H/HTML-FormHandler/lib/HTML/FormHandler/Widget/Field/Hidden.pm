package HTML::FormHandler::Widget::Field::Hidden;
# ABSTRACT: hidden field rendering widget
$HTML::FormHandler::Widget::Field::Hidden::VERSION = '0.40068';
use Moose::Role;
use HTML::FormHandler::Render::Util ('process_attrs');


sub render_element {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $output .= '<input type="hidden" name="';
    $output .= $self->html_name . '"';
    $output .= ' id="' . $self->id . '"';
    $output .= ' value="' . $self->html_filter($result->fif) . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= " />";

    return $output;
}

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    die "No result for form field '" . $self->full_name . "'. Field may be inactive." unless $result;
    my $output = $self->render_element( $result );
    # wrap field unless do_label is set, which would cause unwanted
    # labels to be displayed
    return $self->wrap_field( $result, $output ) if !$self->do_label;
    return $output;
}


use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Hidden - hidden field rendering widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Widget for rendering a hidden field.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
