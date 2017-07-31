package HTML::FormHandler::Widget::Wrapper::Fieldset;
# ABSTRACT: fieldset field wrapper
$HTML::FormHandler::Widget::Wrapper::Fieldset::VERSION = '0.40068';
use Moose::Role;
use namespace::autoclean;

with 'HTML::FormHandler::Widget::Wrapper::Base';
use HTML::FormHandler::Render::Util ('process_attrs');


sub wrap_field {
    my ( $self, $result, $rendered_widget ) = @_;

    my $wattrs = process_attrs($self->wrapper_attributes);
    my $output .= qq{\n<fieldset$wattrs>};
    $output .= qq{\n<legend>} . $self->loc_label . '</legend>';

    $output .= "\n$rendered_widget";

    $output .= qq{\n<span class="error_message">$_</span>}
        for $result->all_errors;
    $output .= "\n</fieldset>";

    return $output;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Widget::Wrapper::Fieldset - fieldset field wrapper

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Wraps a single field in a fieldset.

=head1 NAME

HTML::FormHandler::Widget::Wrapper::Fieldset - fieldset field wrapper

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
