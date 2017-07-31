package HTML::FormHandler::Widget::Wrapper::SimpleInline;
# ABSTRACT: simple field wrapper
$HTML::FormHandler::Widget::Wrapper::SimpleInline::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;

with 'HTML::FormHandler::Widget::Wrapper::Base';


sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    return $rendered_widget if $self->has_flag('is_compound');

    my $output = "\n";
    my $tag = $self->wrapper_tag;
    my $start_tag = $self->get_tag('wrapper_start');
    if( defined $start_tag ) {
        $output .= $start_tag;
    }
    else {
        $output .= "<$tag" . process_attrs( $self->wrapper_attributes($result) ) . ">";
    }

    if ( $self->do_label && length( $self->label ) > 0 ) {
        $output .= $self->do_render_label($result);
    }

    $output .= $rendered_widget;
    $output .= qq{\n<span class="error_message">$_</span>}
        for $result->all_errors;

    my $end_tag = $self->get_tag('wrapper_end');
    $output .= defined $end_tag ? $end_tag : "</$tag>";

    return "$output\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Wrapper::SimpleInline - simple field wrapper

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

This works like the Simple Wrapper, except it doesn't wrap Compound
fields.

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
