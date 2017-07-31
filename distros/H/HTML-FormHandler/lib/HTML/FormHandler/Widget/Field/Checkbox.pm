package HTML::FormHandler::Widget::Field::Checkbox;
# ABSTRACT: HTML attributes field role
$HTML::FormHandler::Widget::Field::Checkbox::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');


sub render_element {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $checkbox_value = $self->checkbox_value;
    my $output = '<input type="checkbox" name="'
        . $self->html_name . '" id="' . $self->id . '" value="'
        . $self->html_filter($checkbox_value) . '"';
    $output .= ' checked="checked"'
        if $result->fif eq $checkbox_value;
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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Field::Checkbox - HTML attributes field role

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Checkbox field renderer

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
