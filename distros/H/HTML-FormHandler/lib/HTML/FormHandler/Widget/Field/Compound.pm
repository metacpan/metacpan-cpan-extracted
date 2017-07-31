package HTML::FormHandler::Widget::Field::Compound;
# ABSTRACT: compound field widget
$HTML::FormHandler::Widget::Field::Compound::VERSION = '0.40068';
use Moose::Role;


sub render_subfield {
    my ( $self, $result, $subfield ) = @_;
    my $subresult = $result->field( $subfield->name );

    return "" unless $subresult;
    return $subfield->render( $subresult );
}

sub render_element {
    my ( $self, $result ) = @_;
    $result ||= $self->result;

    my $output = '';
    foreach my $subfield ( $self->sorted_fields ) {
        $output .= $self->render_subfield( $result, $subfield );
    }
    $output =~ s/^\n//; # remove newlines so they're not duplicated
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

HTML::FormHandler::Widget::Field::Compound - compound field widget

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Widget for rendering a compound field.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
