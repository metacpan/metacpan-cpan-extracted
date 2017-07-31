package HTML::FormHandler::Widget::Field::Textarea;
# ABSTRACT: textarea rendering widget
$HTML::FormHandler::Widget::Field::Textarea::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');

sub render_element {
    my $self = shift;
    my $result = shift || $self->result;

    my $fif  = $self->html_filter($result->fif);
    my $id   = $self->id;
    my $cols = $self->cols || 10;
    my $rows = $self->rows || 5;
    my $name = $self->html_name;
    my $output =
        qq(<textarea name="$name" id="$id")
        . process_attrs($self->element_attributes($result))
        . qq( rows="$rows" cols="$cols">$fif</textarea>);
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

HTML::FormHandler::Widget::Field::Textarea - textarea rendering widget

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
