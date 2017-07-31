package HTML::FormHandler::Widget::Field::Upload;
# ABSTRACT: update field rendering widget
$HTML::FormHandler::Widget::Field::Upload::VERSION = '0.40068';
use Moose::Role;
use HTML::FormHandler::Render::Util ('process_attrs');


sub render_element {
    my ( $self, $result ) = @_;

    $result ||= $self->result;
    my $output;
    $output = '<input type="file" name="';
    $output .= $self->html_name . '"';
    $output .= ' id="' . $self->id . '"';
    $output .= process_attrs($self->element_attributes($result));
    $output .= ' />';
    return $output;
}

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    die "No result for form field '" . $self->full_name . "'. Field may be inactive." unless $result;
    my $output = $self->render_element( $result );
    return $self->wrap_field( $result, $output );
}

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Upload - update field rendering widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Renders an Upload field

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
