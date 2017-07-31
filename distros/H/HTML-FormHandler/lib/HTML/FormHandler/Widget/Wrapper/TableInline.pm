package HTML::FormHandler::Widget::Wrapper::TableInline;
# ABSTRACT: wrapper class for table layout that doesn't wrap compound fields
$HTML::FormHandler::Widget::Wrapper::TableInline::VERSION = '0.40068';
use Moose::Role;
with 'HTML::FormHandler::Widget::Wrapper::Base';
use HTML::FormHandler::Render::Util ('process_attrs');

sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    return $rendered_widget if $self->has_flag('is_compound');

    my $output = "\n<tr" . process_attrs($self->wrapper_attributes($result)) . ">";
    if ( $self->do_label && length( $self->label ) > 0 ) {
        $output .= '<td>' . $self->do_render_label($result) . '</td>';
    }
    $output .= '<td>';
    $output .= $rendered_widget;
    $output .= qq{\n<span class="error_message">$_</span>} for $result->all_errors;
    $output .= "</td></tr>\n";

    return $output;
}

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Wrapper::TableInline - wrapper class for table layout that doesn't wrap compound fields

=head1 VERSION

version 0.40068

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
