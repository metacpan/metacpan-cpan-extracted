package HTML::FormHandler::Widget::Field::Password;
# ABSTRACT: password rendering widget
$HTML::FormHandler::Widget::Field::Password::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;
use HTML::FormHandler::Render::Util ('process_attrs');


sub render_element {
    my $self = shift;
    my $result = shift || $self->result;
    my $t;

    my $output = '<input type="password" name="'
        . $self->html_name . '" id="' . $self->id . '"';
    $output .= qq{ size="$t"} if $t = $self->size;
    $output .= qq{ maxlength="$t"} if $t = $self->maxlength;
    $output .= ' value="' . $self->html_filter($result->fif) . '"';
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

HTML::FormHandler::Widget::Field::Password - password rendering widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Renders a password field

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
